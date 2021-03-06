# s3cmd-zsh-plugin

Zsh autocomplete plugin for [s3cmd](https://s3tools.org/s3cmd)

## Installation

### Oh My Zsh

Clone this repo.

```bash
cd $ZSH_CUSTOM/plugins && git clone https://github.com/FFKL/s3cmd-zsh-plugin.git
```

And add it to the plugins array in `.zshrc`

```bash
plugins=(... s3cmd)
```

## Aliases

| Alias | Command               | Description                       |
| ----- | --------------------- | --------------------------------- |
| sls   | s3cmd ls              | List objects or buckets           |
| spt   | s3cmd put --recursive | Put file or directory into bucket |
| sgt   | s3cmd get --recursive | Get file or directory from bucket |
| srm   | s3cmd rm              | Delete file from bucket           |
| ssyn  | s3cmd sync            | Synchronize a directory tree      |

## Contribution

Contributors are welcome! Please send pull requests improving the usage and fixing bugs.

## License

```
Copyright (C) 2020 Dmitrii Korostelev<ffklffkl@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```
