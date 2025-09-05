from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="groupvan-server-sdk",
    version="1.0.0",
    author="GroupVAN",
    description="Official Python server SDK for GroupVAN V3 API authentication",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/federatedops/GroupVAN-SDK",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: Developers",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
    ],
    python_requires=">=3.10",
    install_requires=[
        "PyJWT>=2.8.0",
        "cryptography>=41.0.0",
        "requests>=2.31.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=4.0.0",
            "black>=23.0.0",
            "flake8>=6.0.0",
            "mypy>=1.0.0",
            "types-requests>=2.31.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "groupvan-server-keygen=groupvan_server_sdk.keygen:main",
        ],
    },
    project_urls={
        "Bug Reports": "https://github.com/federatedops/GroupVAN-SDK/issues",
        "Source": "https://github.com/federatedops/GroupVAN-SDK",
        "Documentation": "https://api.groupvan.com/docs",
    },
)
