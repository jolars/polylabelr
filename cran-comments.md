## Test environments
* local antergos linux installation, R 3.5.1, x64
* Ubuntu Linux 16.04 LTS, R-release, GCC on rhub
* Windows Server 2008 R2 SP1, R-devel, 32/64 bit on rhub
* Debian Linux, R-devel, GCC ASAN/UBSAN on rhub
* Fedora Linux, R-devel, clang, gfortran on rhub
* macOS 10.11 El Capitan, R-release on rhub
* winbuilder devel

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
Maintainer: 'Johan Larsson <johanlarsson@outlook.com>'

New maintainer:
  Johan Larsson <johanlarsson@outlook.com>
Old maintainer(s):
  Johan Larsson <mail@larssonjohan.com>
  
I have switched e-mail address.

## Reverse dependencies

I have checked reverse dependencies using `revdepcheck::revdep_check()`
against polylabelrs two dependencies eulerr and HilbertCurve without
issues.
