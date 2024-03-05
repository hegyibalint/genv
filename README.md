# Gradle Environment Toolkit (genv)

This is a toolkit targeted at people developing Gradle. It takes inspiration from [Python Venvs](https://docs.python.org/3/library/venv.html), which can facilitaty quick, and easy switch between environments. 

This tool tries to do a similar thing, but with Gradle installations. With `genv`, you can:
 * Create, and destroy environments
 * Install a Gradle distribution into environments
 * Use an installed environment as a fully functional local distribution

 ## How to install?

 This tool build upon [fish](https://fishshell.com/), and [fisher](https://github.com/jorgebucaran/fisher).

 If the tools are present, you can install `genv` with:
 ```fish
 fisher install hegyibalint/genv
 ```

 ## How to use?
