# Complete.vim

Interactive completion for any ex-command.

| Interacting with `:edit`                                            | Interacting with [`:Sym`](https://github.com/mattsacks/vim-symbols)            |
| -----------------------------------------------------------------     | -------------------------------------------------------------------------------- |
| ![screenshot](http://f.cl.ly/items/3E2g0Z1j1p250Y0q3e26/complete.png) | ![screenshot-sym](http://f.cl.ly/items/443l1W3I313J381Z272b/complete-symbol.png) |

#### How to use

It's super easy. Just pass the command you want to complete into the `Complete`
function. Just type in:

```vim
:call Complete('e')
```

To start interacting with the output from the `edit` command. But typing out
`:call Complete('...')` all the time isn't so great, so I highly suggest
setting up some mappings.

```vim
nnoremap <Leader>ke :call Complete('e')<CR>
nnoremap <Leader>kb :call Complete('b')<CR>

" for use with fuzzee (http://github.com/mattsacks/vim-fuzzee)
nnoremap <Leader>kf :call Complete('F')<CR>
nnoremap <Leader>kj :call Complete('F app/javascripts*')<CR>
```

Or whatever other mappings suit your fancy.

#### Options

Just one so far!

```vim
call Complete('b', { 'maxheight': 20 })
```

#### About

This plugin was heavily inspired by
[SkyBison](http://github.com/paradigm/SkyBison) and references some of it's
original source code. I wanted to take an alternative approach that didn't use
a chain of `echo` commands to communicate the completions.

There's a lot of work and configuration left to be done with this plugin. Some ideas I have:

* Add a cursor and mappings for arrow keys
* Allow for number assignments for quick-access to results
* Customize position of the window
* Being able to tab through the list

#### License

The MIT License
