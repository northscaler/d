# d
A convenient `deno`-invoking version manager for [Deno](https://deno.land).

## TL;DR
Examples below assume `d` is in your path.

Pass all arguments along the latest version of `deno`:
```shell script
$ d --version # delegates to latest deno
deno 1.1.0
v8 8.4.300
typescript 3.9.2
```
Pass all arguments along to a specific version of `deno`:
```shell script
$ d --use 1.0.0 -- --version # use a specific version of deno
deno 1.0.0
v8 8.4.300
typescript 3.9.2
```
Invoke a script using the latest version of deno:
```shell script
$ d run https://deno.land/std/examples/welcome.ts
Download https://deno.land/std/examples/welcome.ts
Warning Implicitly using master branch https://deno.land/std/examples/welcome.ts
Compile https://deno.land/std/examples/welcome.ts
Welcome to Deno 🦕
```

## Basics
`d` uses the `deno` version specified in this order:
1. `d` command line argument `-u` or `--use`.
2. Environment variable `DENO_VERSION`.
3. The `d` rc file, default `.drc`, up the current directory tree, beginning in the current directory.
4. The `d` rc file in the user's home directory.
5. The `d` rc file in the d home directory.
6. The file `.drc` in the `d` home directory.

If not found, `d` downloads the specified, or latest if unspecified, version of `deno` and uses that.

Simply store the `deno` version number in the `.drc` file wherever you want to use it acording to the rules above.

By default, `d` stores `deno` versions in `~/.d`.
Downloaded zip distros of deno are cached in the `d` home dir.

Override that location by using `d` argument `--d-home` or setting environment variable `DENO_D_HOME`.

By default, all arguments are passed along to `deno`, unless there is a `--` argument specified.
In that case, all arguments passed along to `d` precede the `--`, and all arguments following `--` are passed along to `deno`.
