"""c64kit/build/build_system.py

Incremental Python Build System for C64 games.
Parses c64project.yaml, checks dependencies/modified times, and compiles using 'xa'.
"""

import os
import sys
import yaml
import subprocess
import argparse
from typing import Dict, Any, List, Optional

__all__ = [
    "C64Project",
    "load_project_config",
    "run_assembler",
    "package_project",
    "is_rebuild_required",
    "build_project",
]


class C64Project:
    """Class representing a C64 project parsed from c64project.yaml."""

    def __init__(self, config_dict: Dict[str, Any]):
        self.config = config_dict
        self.project = config_dict.get("project", {})
        self.build_settings = config_dict.get("build", {})
        self.assets = config_dict.get("assets", {})
        self.testing = config_dict.get("testing", {})
        self.packaging = config_dict.get("packaging", {})

        # Extracted paths
        self.name: str = self.project.get("name", "C64 Game")
        self.version: str = self.project.get("version", "1.0.0")
        self.assembler: str = self.build_settings.get("assembler", "xa")
        self.flags: List[str] = self.build_settings.get("flags", ["-XMASM"])
        self.source_dirs: List[str] = self.build_settings.get("source_dirs", ["."])
        self.main_file: str = self.build_settings.get("main", "main.asm")
        self.output_file: str = self.build_settings.get("output", "build/out.prg")


def load_project_config(filepath: str) -> C64Project:
    """Loads and parses c64project.yaml into a C64Project object.

    Args:
        filepath: Path to c64project.yaml.

    Returns:
        C64Project object containing configuration settings.
    """
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Project configuration file '{filepath}' not found.")

    with open(filepath, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    return C64Project(config)


def get_latest_mtime(paths: List[str]) -> float:
    """Gets the latest modification time of any file in the given paths (files or directories).

    Args:
        paths: List of directory/file paths.

    Returns:
        The maximum modification timestamp found.
    """
    latest = 0.0
    for path in paths:
        if not os.path.exists(path):
            continue
        if os.path.isdir(path):
            for root, _, files in os.walk(path):
                for f in files:
                    # Ignore editor backup/temp files
                    if f.startswith(".") or f.endswith(("~", ".tmp")):
                        continue
                    f_path = os.path.join(root, f)
                    try:
                        latest = max(latest, os.path.getmtime(f_path))
                    except OSError:
                        pass
        else:
            try:
                latest = max(latest, os.path.getmtime(path))
            except OSError:
                pass
    return latest


def is_rebuild_required(project: C64Project) -> bool:
    """Determines whether a rebuild is required based on file modification times.

    Args:
        project: C64Project config.

    Returns:
        True if any source/asset file is newer than the output file.
    """
    output_path = project.output_file
    if not os.path.exists(output_path):
        return True

    # Check if packaged files are missing
    base_dir = os.path.dirname(output_path)
    filename_no_ext = os.path.splitext(os.path.basename(output_path))[0]

    if project.packaging.get("d64"):
        d64_path = os.path.join(base_dir, f"{filename_no_ext}.d64") if base_dir else f"{filename_no_ext}.d64"
        if not os.path.exists(d64_path):
            return True

    if project.packaging.get("crt"):
        crt_path = os.path.join(base_dir, f"{filename_no_ext}.crt") if base_dir else f"{filename_no_ext}.crt"
        if not os.path.exists(crt_path):
            return True

    output_mtime = os.path.getmtime(output_path)

    # Collect all sources & assets paths
    all_paths = []
    all_paths.extend(project.source_dirs)
    all_paths.append(project.main_file)

    for asset_path in project.assets.values():
        if isinstance(asset_path, str):
            all_paths.append(asset_path)
        elif isinstance(asset_path, list):
            all_paths.extend(asset_path)

    latest_src_mtime = get_latest_mtime(all_paths)
    return latest_src_mtime > output_mtime


def run_assembler(project: C64Project) -> bool:
    """Invokes the cross-assembler (e.g. 'xa') via subprocess to build the project.

    Args:
        project: C64Project config.

    Returns:
        True if assembly succeeded, False otherwise.
    """
    # Create output directory if it doesn't exist
    out_dir = os.path.dirname(project.output_file)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    cmd = [project.assembler] + project.flags
    # Add input and output parameters
    cmd.extend([project.main_file, "-o", project.output_file])

    print(f"Executing: {' '.join(cmd)}")
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode == 0:
            print(f"Assembly Succeeded. Created '{project.output_file}'.")
            if res.stdout:
                print(res.stdout)
            return True
        else:
            print("Assembly Failed with errors:")
            print(res.stderr)
            return False
    except FileNotFoundError:
        print(f"Error: Cross-assembler '{project.assembler}' is not installed or not in PATH.")
        return False


def package_project(project: C64Project) -> bool:
    """Packages the compiled output file (.prg) into configured target formats (.d64, .crt).

    Args:
        project: C64Project config.

    Returns:
        True if packaging succeeded or was not needed, False if packaging failed.
    """
    if not project.packaging:
        return True

    prg_path = project.output_file
    if not os.path.exists(prg_path):
        print(f"Error: Output file '{prg_path}' does not exist. Cannot package.")
        return False

    base_dir = os.path.dirname(prg_path)
    filename_no_ext = os.path.splitext(os.path.basename(prg_path))[0]

    success = True

    # 1. Generate .d64 disk image
    if project.packaging.get("d64"):
        d64_path = os.path.join(base_dir, f"{filename_no_ext}.d64") if base_dir else f"{filename_no_ext}.d64"
        print(f"Packaging: Generating disk image '{d64_path}'...")
        # Remove existing file if any
        if os.path.exists(d64_path):
            try:
                os.remove(d64_path)
            except OSError:
                pass

        # c1541 format command
        cmd_format = ["c1541", "-format", f"{filename_no_ext[:16]},01", "d64", d64_path]
        # c1541 write command
        cmd_write = ["c1541", d64_path, "-write", prg_path, filename_no_ext[:16]]

        try:
            res_format = subprocess.run(cmd_format, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            if res_format.returncode != 0:
                print(f"Error: Failed to format disk image {d64_path}. Error:\n{res_format.stderr}")
                success = False
            else:
                res_write = subprocess.run(cmd_write, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                if res_write.returncode != 0:
                    print(f"Error: Failed to write to disk image {d64_path}. Error:\n{res_write.stderr}")
                    success = False
                else:
                    print(f"Disk image '{d64_path}' created successfully.")
        except FileNotFoundError:
            print("Warning: 'c1541' utility (part of VICE) is not installed or not in PATH. Skipping .d64 generation.")
            pass

    # 2. Generate .crt cartridge
    crt_option = project.packaging.get("crt")
    if crt_option:
        crt_path = os.path.join(base_dir, f"{filename_no_ext}.crt") if base_dir else f"{filename_no_ext}.crt"
        print(f"Packaging: Generating cartridge '{crt_path}'...")

        # Determine cartridge type
        cart_type = "normal"
        if isinstance(crt_option, str):
            cart_type = crt_option

        # Remove existing file if any
        if os.path.exists(crt_path):
            try:
                os.remove(crt_path)
            except OSError:
                pass

        # cartconv command
        cmd_cart = ["cartconv", "-p", "-t", cart_type, "-i", prg_path, "-o", crt_path]

        try:
            res_cart = subprocess.run(cmd_cart, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            if res_cart.returncode != 0:
                print(f"Error: Failed to convert cartridge {crt_path}. Error:\n{res_cart.stderr}")
                success = False
            else:
                print(f"Cartridge '{crt_path}' created successfully with type '{cart_type}'.")
        except FileNotFoundError:
            print("Warning: 'cartconv' utility (part of VICE) is not installed or not in PATH. Skipping .crt generation.")
            pass

    return success


def build_project(project_path: str = "c64project.yaml", force: bool = False) -> bool:
    """Builds the C64 project using incremental tracking.

    Args:
        project_path: Path to project configuration YAML.
        force: If True, forces a rebuild even if files are unchanged.

    Returns:
        True if build or skip was successful, False if build failed.
    """
    try:
        project = load_project_config(project_path)
    except Exception as e:
        print(f"Failed to load project config: {e}")
        return False

    print(f"Building Project: {project.name} (v{project.version})")

    if not force and not is_rebuild_required(project):
        print("Project is up-to-date. Rebuild skipped.")
        return True

    success = run_assembler(project)
    if success:
        success = package_project(project)
    return success


def main() -> None:
    """CLI entry point for building projects."""
    parser = argparse.ArgumentParser(description="Build automation for C64 projects.")
    parser.add_argument("--config", default="c64project.yaml", help="Path to c64project.yaml config file")
    parser.add_argument("--force", action="store_true", help="Force rebuild regardless of timestamps")

    # If argparse is parsed via testing hooks, handle parsing
    args = parser.parse_args()

    success = build_project(args.config, force=args.force)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
