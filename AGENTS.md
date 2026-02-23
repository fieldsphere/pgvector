# AGENTS.md

## Cloud-specific instructions

### Overview

pgvector is a PostgreSQL C extension (not a standalone app). The development cycle is: edit C code, `make`, `sudo make install`, then test against a running PostgreSQL instance.

### Prerequisites (installed via VM snapshot)

- PostgreSQL 17 (server + `postgresql-server-dev-17`)
- `libipc-run-perl` (needed for TAP tests)
- `gcc`, `make`, `clang` (build tools)

### Starting PostgreSQL

```sh
sudo pg_ctlcluster 17 main start
```

The workspace directory needs write permission for the `postgres` user to run tests:

```sh
sudo chmod o+w /workspace
```

### Build & install

```sh
make && sudo make install
```

After code changes, you must re-run `make && sudo make install` before testing. PostgreSQL loads the shared library from its `$libdir`, so a restart is **not** needed for function-level changes, but **is** needed if the shared library signature changes.

### Testing

See the README "Contributing" section for full details. Summary:

- **Regression tests**: `sudo -u postgres make installcheck`
- **TAP tests**: `sudo -u postgres make prove_installcheck` (takes ~3-4 minutes)
- **Single regression test**: `sudo -u postgres make installcheck REGRESS=functions`
- **Single TAP test**: `sudo -u postgres make prove_installcheck PROVE_TESTS=test/t/001_ivfflat_wal.pl`

### Gotchas

- Tests must run as the `postgres` OS user (`sudo -u postgres`).
- The `postgres` user needs write access to the workspace directory (for `regression.out` etc.), so run `sudo chmod o+w /workspace` if freshly cloned.
- There is no linter beyond the C compiler warnings (`-Wall` etc.) which are enforced during `make`.
