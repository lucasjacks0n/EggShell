#!/usr/bin/python
from modules import server
from modules import helper as h
import sys, os
from eggshell import EggShell
import afl


if __name__ == "__main__":
    afl.init()
    eggshell = EggShell()
    eggshell.menu()
