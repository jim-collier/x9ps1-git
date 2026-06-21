<!-- markdownlint-disable MD007 -- Unordered list indentation -->
<!-- markdownlint-disable MD010 -- No hard tabs -->
<!-- markdownlint-disable MD033 -- No inline html -->
<!-- markdownlint-disable MD055 -- Table pipe style [Expected: leading_and_trailing; Actual: leading_only; Missing trailing pipe] -->
<!-- markdownlint-disable MD041 -- First line in a file should be a top-level heading -->

<div align="center">

[![!#/bin/bash](https://img.shields.io/badge/-%23!%2Fbin%2Fbash-1f425f.svg?logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Lifecycle: Stable](https://img.shields.io/badge/Lifecycle-Stable-brightgreen)
![Support](https://img.shields.io/badge/Support-Maintained-brightgreen)
![Status: Passing](https://img.shields.io/badge/Status-Passing-brightgreen)

</div>
<!--
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![Lifecycle: Alpha](https://img.shields.io/badge/Lifecycle-Alpha-orange)
![Lifecycle: Beta](https://img.shields.io/badge/Lifecycle-Beta-yellow)
![Lifecycle: RC](https://img.shields.io/badge/Lifecycle-RC-blue)
![Lifecycle: Stable](https://img.shields.io/badge/Lifecycle-Stable-brightgreen)
![Lifecycle: Deprecated](https://img.shields.io/badge/Lifecycle-Deprecated-red)
![Status: Deprecated](https://img.shields.io/badge/Status-Deprecated-orange)
![Status: Archived](https://img.shields.io/badge/Status-Archived-lightgrey)
![Lifecycle: EOL](https://img.shields.io/badge/Lifecycle-EOL-lightgrey)
![Coverage](https://img.shields.io/badge/Coverage-25%25-red)
![Coverage](https://img.shields.io/badge/Coverage-50%25-orange)
![Coverage](https://img.shields.io/badge/Coverage-75%25-yellow)
![Coverage](https://img.shields.io/badge/Coverage-90%25-brightgreen)
![Status: Passing](https://img.shields.io/badge/Status-Passing-brightgreen)
![Status: Failing](https://img.shields.io/badge/Status-Failing-red)
-->

<!-- omit in TOC -->
# x9ps1-git

<img src="https://github.com/jim-collier/x9ps1-git/blob/main/assets/mascot.png?raw=true" alt="x9ps1-git" width="128"/>

Inspired by - but improves upon - the [tide](https://github.com/IlanCosman/tide) prompt for [fish](https://fishshell.com/) shell.

But for good 'ol regular bash terminals...

- Which is a bonus if you prefer Bash over Fish as a syntax and language.
- Fish's suggestion/auto-completion functionality is admittedly really cool - though the `ble` project for Bash is arguably nearly as good if not better, taste-dependent.

<!-- omit in TOC -->
## Table of contents

- [Overview](#overview)
- [Installation](#installation)
- [Feature comparison](#feature-comparison)
- [Other notes](#other-notes)
- [But is it REALLY better than Fish](#but-is-it-really-better-than-fish)

## Overview

The tide prompt for fish shell is fantastic for working with `git` on the command-line. The prompt tells you what branch your on, and if there are uncommitted changes.

## Installation

~~~bash
## Download to any directory in $PATH (/usr/local/sbin in this example)
cd /usr/local/sbin
sudo wget https://raw.githubusercontent.com/jim-collier/x9ps1-git/main/x9ps1-git  ## No
sudo chmod +x x9ps1-git

## Execute now to apply to current terminal prompt
PROMPT_COMMAND='PS1=`x9ps1-git`'

## Add the command to your personal .bashrc so that all terminals get the prompt
echo -e "\nPROMPT_COMMAND='PS1=`x9ps1-git`'\n" | tee -a ~/.bashrc
~~~

*Note: If installing to a user folder rather than system, don't prepend `sudo` to commands.*

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

## But is it REALLY better than Fish

No.

Fish (which enables Tide to exist) is an amazing group effort of real programming. It's an altogether new shell.

OTOH this is just a bash script. Granted, a script that took years of fine-tuning (not continuously of course), but just a script.

But in spite of what was designed to feel like "configuration by declaration", it is in fact "configuration by procedural code".

Want multiple configurations? Then make multiple copies of the script, and edit each one.
