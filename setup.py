from setuptools import setup, find_packages

setup(
    name="c64kit",
    version="2.0.0",
    description="C64 Game Development Kit (c64kit)",
    author="alby69",
    packages=find_packages(),
    install_requires=[
        "pygame>=2.0.0",
        "numpy>=1.20.0",
        "Pillow>=8.0.0",
        "pyyaml>=5.0.0",
    ],
    extras_require={
        "test": [
            "pytest>=6.0.0",
        ]
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.11",
)
