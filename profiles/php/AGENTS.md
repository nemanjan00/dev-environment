
# PHP Profile

General-purpose **PHP 8** development, driven by **Composer**. Built for the
kind of project whose `composer.json` targets `^7.2|^8.0` and leans on the
async React/Guzzle stack (event loops, MQTT, SOCKS/HTTP proxies, FBNS) plus
crypto/imaging extensions.

## What's installed (native, package-based)

- **`php`** (Arch `extra`, currently 8.5) — the CLI interpreter (`php`,
  `php-config`, `phpize`). Satisfies the `^8.0` half of `^7.2|^8.0`.
- **`php-gd`** — the `gd` image extension (its own Arch package).
- **`gmp`** — the system GMP library, so PHP's bundled `gmp` module can load.
- **`composer`** — the dependency manager. This is *the* way to install the
  userland libraries in `composer.json`; run it in your project.

## Enabled extensions

The required extensions are turned on via a drop-in at
`/etc/php/conf.d/dev-extensions.ini` (Arch's php scans `conf.d`):

| Extension  | How it's provided                              |
|------------|------------------------------------------------|
| `curl`     | bundled shared module, enabled by stock php.ini |
| `mbstring` | **compiled in statically** — always on, no toggle |
| `exif`     | bundled shared module, enabled here            |
| `bcmath`   | bundled shared module, enabled here            |
| `gmp`      | bundled shared module + system `gmp` lib        |
| `gd`       | `php-gd` package, enabled here                 |
| `zlib`     | **compiled in statically** — always on, no toggle |

Verify what's live with `php -m` (or `php -i | grep <ext>`).

## Composer libraries are NOT baked in

The `require` block (lazyjsonmapper, guzzle, react/*, clue/*, ramsey/uuid,
phpseclib, symfony/process, …) is **application** code, not system tooling — it
is not installed in the image. Fetch it per project:

```sh
cd /work/project
composer install            # from an existing composer.lock / composer.json
# or, starting fresh:
composer require guzzlehttp/guzzle react/event-loop phpseclib/phpseclib
```

Composer's own cache lives under `~/.composer` / `~/.cache/composer`, which is
**ephemeral** here — only `/work/project` (with its `vendor/`) persists. A
re-`composer install` after a container restart is normal.

## What's deliberately *not* here

- **No web/SAPI stack** — no `php-fpm`, `php-apache`, nginx. This profile is
  for CLI/async PHP (React event loops, workers, scripts), not for serving a
  site. Add a SAPI package if you truly need one.
- **No database driver extensions** (`php-sqlite`, `php-pgsql`, …) — none are
  in the target `require`. Install the matching `php-*` package and add an
  `extension=` line if a project needs one.
- **No PHP 7.x** — Arch ships only current PHP (8.5) and `php-legacy` (8.3);
  neither is 7.x. Everything in the target `require` also accepts `^8.0`, so
  8.x is the intended runtime here.
- **No global framework CLIs** (Laravel, Symfony console, PHPUnit) — pull them
  in per project via `composer require --dev` when needed.
