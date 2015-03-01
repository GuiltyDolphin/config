#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess

from collections import namedtuple
from functools import partial

import getopt  # Use this rather than argparse for compatibility

import logging as log
import time
import shutil

HOME = os.path.expandvars("$HOME")

LINK_BASE = HOME

DOT_DIR = os.path.dirname(os.path.realpath(__file__))

# Create instances of this when wanting to create new links.
# The link_type is for determining the link path.
Link = namedtuple("Link", ["parent", "name", "link_type"])

newpath = os.path.join


def resolve_link_path(link):
    """Return the full path of link's name."""
    if isinstance(link.parent, str):
        return newpath(link.parent, link.name)
    else:
        return newpath(resolve_link_path(link.parent), link.name)


def get_link_path(link):
    """Get the target and path to link to for a particular Link"""
    target = resolve_link_path(link)
    link_type = link.link_type
    if link_type == "default":
        link_path = newpath(LINK_BASE, os.path.basename(link.name))
    else:
        raise NotImplementedError
    return (target, link_path)


def require_yes_no(prompt):
    """Return a boolean value based on a user input of 'yes' or 'no'."""
    response = input(prompt + " [y/n]: ")
    affirmatives = ('y', 'yes')
    negatives = ('n', 'no')
    while not response.casefold() in affirmatives + negatives:
        response = input("Response must be y[es] or n[o]: ")
    return response in affirmatives


def get_files():
    """Retrieve the files to be linked"""
    all_files = {}

    def map_partial(fn, *args):
        result = []
        for arg in args:
            if isinstance(arg, list):
                result.append(fn(arg))
            else:
                result.append(fn(arg))
        return result

    def link_default(parent, name, link_type="default"):
        return Link(parent, name, link_type)

    def create_links(base, *args):
        return map_partial(partial(link_default, base), *args)

    # Bash files
    bash_dir = Link(DOT_DIR, "bash", None)
    bash_files = create_links(
        bash_dir,
        ".bash/.bashrc",
        ".profile")

    all_files["bash"] = bash_files

    # Git files
    git_dir = Link(DOT_DIR, "git", None)
    git_files = create_links(
        git_dir,
        ".gitconfig")

    all_files["git"] = git_files

    # Haskell files
    haskell_dir = Link(DOT_DIR, "haskell", None)
    ghci_files = create_links(
        haskell_dir,
        ".ghci")
    all_files["ghci"] = ghci_files

    # Tmux files
    tmux_dir = Link(DOT_DIR, "tmux", None)
    tmux_files = create_links(
        tmux_dir,
        ".tmux.conf")
    tmuxinator_files = create_links(
        tmux_dir,
        ".tmuxinator")

    all_files["tmux"] = tmux_files
    all_files["tmuxinator"] = tmuxinator_files

    # Vim files
    vim_dir = Link(DOT_DIR, "vim", None)
    vim_files = create_links(
        vim_dir,
        ".vimrc")
    all_files["vim"] = vim_files

    return all_files


def backup_overwrite(to_backup, backup_parent):
    """Create a backup of link_path in an appropriate directory"""
    backup_dir = newpath(
        backup_parent, ".dotfile_backup", time.strftime("%F"))
    if not os.path.exists(backup_dir):
        log.info("Creating directory {}".format(backup_dir))
        os.mkdir(backup_dir)
    else:
        log.debug("Directory {} already exists".format(backup_dir))
    target = newpath(backup_dir, to_backup)
    if os.path.exists(target):
        log.debug("File {} already exists, appending timestamp".format(target))
        target = target + "-" + time.strftime("%s")
    shutil.move(to_backup, target)
    log.debug("File {} moved to {}".format(to_backup, target))


def create_soft_link(target, name):
    """Create a soft link to target with name 'name'."""
    try:
        subprocess.call(["ln", "-s", target, name])
    except subprocess.CalledProcessError:
        log.error("Failed to link {} to {}".format(target, name))
    else:
        log.debug("Linked file: {} to {}".format(target, name))


def link_files(req_prog, files):
    """Create symlinks for dotfiles"""
    try:
        subprocess.check_output(["which", req_prog])
    except subprocess.CalledProcessError:
        log.warn("{} not found, skipping related dotfiles".format(req_prog))
        return 1
    else:
        for (target, link_path) in map(get_link_path, files):
            if os.path.exists(link_path):
                if os.path.samefile(target, link_path):
                    log.debug("Skipping file {} - Already linked".format(
                        link_path))
                else:
                    overwrite = require_yes_no(
                        "File {} already exists, backup and overwrite?")
                    if overwrite:
                        backup_overwrite(target, link_path)
                        create_soft_link(target, link_path)
                        continue
                    else:
                        log.debug(
                            "Skipping file {} - File exists".format(link_path))
                        continue
            else:
                create_soft_link(target, link_path)


def setup_solarized_colors(color_dir):
    """Download files needed for solarized color in terminal"""
    color_path = newpath(color_dir, ".dir_colors")
    file_url = ("https://raw.githubusercontent.com"
                "/seebi/dircolors-solarized/"
                "master/dircolors.256dark")
    if os.path.exists(color_path):
        log.debug("{} already exists".format(color_path))
        return
    else:
        log.info("{} not found, downloading from github...".format(
            color_path))
    try:
        subprocess.check_call(["wget", "-q", file_url, "-O", color_path])
    except subprocess.CalledProcessError:
        log.error("Could not download file {}".format(file_url))
    else:
        log.debug("File successfully downloaded.")


def get_options(sys_args):
    """Retrieve user options"""
    def usage():
        """Print the script's usage"""
        print("""Installer for GuiltyDolphin's dotfiles.
Hosted at https://www.github.com/GuiltyDolphin/config

Usage: python install.py [long option] [option] ...
long options:
  --help (-h) - Display this help message
  --link - Create symlinks to dotfiles
  --setup-colors - Download solarized colors
  --full - Setup everything
  --verbose (-v) - Verbose output
""")

    try:
        opts, args = getopt.getopt(
            sys_args, "hv",
            ["help", "link", "setup-colors", "full", "verbose"])
    except getopt.GetoptError as err:
        print(err)
        usage()
        sys.exit(2)

    options = {"link": True,
               "color": False,
               "verbose": False}
    setups = ["link", "color"]
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit()
        elif opt == "--link":
            options["link"] = True
        elif opt == "--setup-colors":
            options["color"] = True
        elif opt == "--full":
            for setup in setups:
                options[setup] = True
        elif opt in ("-v", "--verbose"):
            options["verbose"] = True
        else:
            print("Unhandled option")
            sys.exit(2)
    return options


def main():
    options = get_options(sys.argv[1:])
    if options["verbose"]:
        log.basicConfig(format="%(levelname)s: %(message)s", level=log.DEBUG)
    else:
        log.basicConfig(format="%(message)s", level=log.INFO)

    if options["link"]:
        log.info("Linking dotfiles...")
        prog_files = get_files()
        for (prog, files) in prog_files.items():
            log.debug("Linking files for {}".format(prog))
            link_files(prog, files)
    if options["color"]:
        log.info("Setting up colors...")
        setup_solarized_colors(HOME)


if __name__ == '__main__':
    main()
