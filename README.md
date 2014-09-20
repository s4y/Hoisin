# Hoisin

Hoisin is an HTML-based shell with a few ambitious goals:

- Commands’ inputs and outputs can be, instead of a stream of text, a data structure like a list or a dictionary.

- Long-running commands can update their output. For example, a long running version of `ps` will post updates to its output as processes come and go.

- Instead of taking over the terminal, commands can instanciate HTML-based UIs and communicate with them out of band.

- If you want to save a command's output or keep working while a long running command does its thing, you can "fork" a new shell. This takes the form of iPython-style cells: each cell has its own command history and can run commands independently.

## Examples

### Hoisin running stock `ls`

![](https://sidnicious.github.io/Hoisin/readme/ls.png)

### Hoisin running `psw`, a live-updating `ps`

![](https://sidnicious.github.io/Hoisin/readme/ls-and-psw.png)
