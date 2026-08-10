from setuptools import setup, find_packages

setup(
    name="c64kit",
    version="1.0.0",
    description="A Python framework and tools for C64 game development and emulation emulation",
    author="alby69",
    packages=find_packages(),
    install_requires=[
        "pygame>=2.6.0",
        "numpy>=2.0.0",
        "pyyaml>=6.0",
        "Pillow>=10.0.0",
    ],
    extras_require={
        "test": [
            "pytest>=9.0.0",
        ],
    },
    python_requires=">=3.11",
)
