<!-- omit in TOC -->
# x9ps1-git

Inspired by - but improves upon - the [tide](https://github.com/IlanCosman/tide) prompt for [fish](https://fishshell.com/) shell.

But for good 'ol regular bash terminals. (Which is a bonus if you prefer Bash over Fish as a syntax and language. But Fish's suggestion/auto-completion functionality is admittedly really, really cool.)

<!-- omit in TOC -->
## Table of contents

- [Overview](#overview)
- [Installation](#installation)
- [Feature comparison](#feature-comparison)
- [Other notes](#other-notes)
- [Slow down there tonto](#slow-down-there-tonto)

## Overview

The tide prompt for fish shell is fantastic for working with `git` on the command-line. The prompt tells you what branch your on, and if there are uncommitted changes.

## Installation

1. Change to a directory that is in your path, that you wish to install this to. (It must be in your path.)
1. Execute: `wget https://raw.githubusercontent.com/jim-collier/x9ps1-git/main/x9ps1-git`
   - If it's a system directory, you'll need to prepend `sudo` to that command.
1. Execute: `sudo chmod +x x9ps1-git`
1. Edit your `~/.bashrc` and append to the end, verbatim:
   - ``PROMPT_COMMAND='PS1=`x9ps1-git`'``

## Feature comparison

| Feature                                          | Exists in fish/tide? | Exists in x9ps1-git? |
|:---                                              | :---: | :---: |
| Doesn't show git info if not in a repo directory | ✔     | ✔     |
| Shows active repo                                |       | ✔     |
| Shows active branch                              | ✔     | ✔     |
| Shows if merge needed                            | ✔     | ✔     |
| Shows if push needed                             |       | ✔     |
| Shows time of last prompt/status update          |       | ✔     |
| Compresses path display (a pro and a con)        | ✔     |       |
| Has a cool, memorable name                       | ✔     |       |
| Stupid-easy to customize prompt¹                 |       | ✔     |

**Footnotes**
¹ *Includes defined color macros and defined prompt primitives.*

## Other notes

- The program is a fairly small bash script can be easily edited - to add, remove, and/or reorganize the prompt.
- Colors can be assigned to individual elements.
- If bash is not currently in a git repository folder, the prompt looks similar to most stock prompts. But if it is in a git folder, it expands to two lines in order to include all of the information.
- The hostname element is already nested in the analogue to a switch or case block, so that the hostname can be colored differently depending on the name. (In case this script is synced across multiple hosts.)

## Slow down there tonto

"Tonto" is an anachronistic - and to some, highly offensive - term. So I changed it to lower-case so as to not be a proper noun. Now it's all good. Moving on:

Fish (which enables Tide to exist) is an amazing group effort of real programming. It's an altogether new shell.

This, OTOH, is just a bash script. Granted, a bash script that took many hours to write and debug, and possibly even more hours figuring out how to get it to be dynamically updated.

But in spite of what was designed to feel like "configuration by declaration", it is in fact "configuration by procedural code". Want multiple configurations? Then make multiple copies of the script, and edit each one. That shortcoming could be worked around by the typical scripting solution of a slight refactoring that allows sourcing this script, from multiple wrapper script that potentially override the default values defined in this one. That's left up to a brief exercise by the user. (Send me a PR if you do.)
