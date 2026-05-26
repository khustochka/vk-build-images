# vk-build-images

Dockerfiles and GitHub Actions workflows for building `base` and `build` images
used by other projects. The goal is to avoid reinstalling system packages
on every application image build, and to pin their versions for reproducibility.

Multi-arch (amd64 + arm64) images are pushed to ECR Public:

### Quails

- `quails-base` (`quails/base.Dockerfile`) — Ruby plus runtime OS packages
  (libvips, libjpeg, libjemalloc, etc.). Used as the final stage of the
  application image.
- `quails-build` (`quails/build.Dockerfile`) — extends `quails-base` with
  compilers, dev headers, Node.js, and Yarn. Used for the gem- and
  asset-compilation stages of the application image.

### Kjogvi

- `kjogvi-base` (`kjogvi/base.Dockerfile`) — Debian plus runtime OS packages
  (libstdc++, openssl, libncurses, postgresql-client, locales, etc.). Used as
  the final stage of the application image.
- `kjogvi-build` (`kjogvi/build.Dockerfile`) — `hexpm/elixir` on the same
  Debian release, plus compilers, git, and Node.js. Used for the deps-,
  compile-, and asset-build stages of the application image.

Unlike quails, the two kjogvi images are independent (the build image is not
`FROM` the base image) because the builder needs Erlang/Elixir from
`hexpm/elixir`, while the runtime stays on plain Debian. They are kept on the
same Debian release via the `DEBIAN_VERSION` build arg.

Builds run on push to `main`, or via `workflow_dispatch`. On success, a 
`repository_dispatch` event notifies the other repo, where a PR is created,
tests are run, and images are built.
