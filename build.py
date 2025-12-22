#!/usr/bin/python3
import base64
import hashlib
import json
import os
import zlib

PACKAGES_ROOT_SRC_DIR = "./packages"
PACKAGES_SRC_DIR = "source"
MANIFEST_FILE = "manifest.json"
MANIFEST_FIELDS = ["license", "authors", "maintainers", "version", "dependencies"]
PACKAGES_POOL_DIR = "./pool"
INDEX_FILE = "index.json"


def get_all_packages():
    return map(lambda entry: entry.name, os.scandir(PACKAGES_ROOT_SRC_DIR))


def get_package_files(name):
    path = f"{PACKAGES_ROOT_SRC_DIR}/{name}/{PACKAGES_SRC_DIR}/"
    rtn = []

    for root, _, files in os.walk(path):
        root_path = "" if root == path else root.removeprefix(path) + "/"
        rtn.extend(map(lambda file: root_path + file, files))

    return rtn


def get_manifest(name):
    path = f"{PACKAGES_ROOT_SRC_DIR}/{name}/{MANIFEST_FILE}"

    print("[i] Reading manifest")

    try:
        with open(path) as file:
            manifest = json.load(file)

            for key in MANIFEST_FIELDS:
                if key not in manifest:
                    print(f"[!] Package manifest is incomplete (missing '{key}')")

            return manifest
    except FileNotFoundError:
        print("[!] Package is invalid (no manifest)")
    except json.JSONDecodeError:
        print("[!] Package is invalid (unreadable manifest)")


def build_package(name):
    manifest = get_manifest(name)

    if manifest is not None:
        manifest["files"] = {}

        for path in get_package_files(name):
            print(f"[+] {path}")
            with open(
                f"{PACKAGES_ROOT_SRC_DIR}/{name}/{PACKAGES_SRC_DIR}/{path}"
            ) as file:
                content = file.read()

                manifest["files"][path] = {
                    "content": content,
                    "digest": hashlib.sha256(content.encode()).hexdigest(),
                }

        return manifest


def compress(package):
    return base64.b64encode(
        zlib.compress(json.dumps(package).encode(), level=zlib.Z_BEST_COMPRESSION)
    )


def write_package(name):
    print(f"Packaging {name}")
    package = build_package(name)

    if package is not None:
        data = compress(package)

        with open(
            f"{PACKAGES_POOL_DIR}/{name}.{package['version']}.ccp", mode="w"
        ) as file:
            file.write(data.decode())

        return {
            "version": package["version"],
            "digest": hashlib.sha256(data).hexdigest(),
        }


if __name__ == "__main__":
    try:
        os.makedirs(PACKAGES_POOL_DIR)
    except:
        pass

    packages = {}

    for package in get_all_packages():
        index = write_package(package)

        if index is not None:
            packages[package] = index

    print("Writing index")
    with open(f"{PACKAGES_POOL_DIR}/{INDEX_FILE}", mode="w") as file:
        file.write(json.dumps(packages))
