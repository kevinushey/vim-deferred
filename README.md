# deferred.vim

Defer the execution of Vim commands.

This plugin was primarily made so I could source some
particularly heavily Vim scripts 'lazily', so that Vim
itself could open and render a little bit faster.

# Wait, What?

This plugin provides a means for delaying the execution of
a command until certain `autocmd` events are fired. This
means you can attach one-time executions to events like:

- The user types `:`,
- The user enters insert mode,
- The user opens a new file

And so on. The main utility gained relative to basic
`autocmd`s is that this plugin goes out of its way to
ensure each command is executed only once, rather than
tying its execution to every event.

# Usage and Motivation

This pluging was basically developed to provide a means
for lazily sourcing a Vim script. Here's how I'm using it
right now, to lazily load some supplementary Vim scripts
which take just a little bit too long to load at startup:

```viml
autocmd VimEnter * Defer
            \ source ~/.vim/startup/spf13.vim |
            \ source ~/.vim/startup/global.vim |
            \ redraw
```

Note that the only reason I `autocmd VimEnter` that is
because the `Defer` command (exported by this package)
doesn't seem to be available at that time. It could be
because I am not properly loading it or because I need to
move the folder from `plugin/` to `autoloads/`.

# License

Copyright (c) Kevin Ushey. Distributed under the same
terms as Vim itself. See `:help license` for more details.
