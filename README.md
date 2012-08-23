[![build status](https://secure.travis-ci.org/duostack/duostack-client.png)](http://travis-ci.org/duostack/duostack-client)
Duostack Command Line Client
============================

A command line client for the Duostack Ruby and Node.js hosting platform.

This project contains the client files themselves (under `src/`), along with the scripts and support files needed to build gem, npm, and tgz packages of the client.


Installation
------------

Install as a gem or npm package:

    gem install duostack
    
    npm install duostack

Or just copy the contents of `src/` to a location in your `PATH`, such as `/usr/local/bin`.


Usage
-----

Consult `duostack help` after installing for client usage details, or go to <http://docs.duostack.com/command-line-client-command-reference>.

To build gem/npm/tgz packages of the client, run `rake package`. Packages will be written to `packages/`. To build previous versions, just check out the git tag for the version number of interest, and run the rake task.


Running Tests
-------------

The test suite is being continuously improved. Currently, the test suite depends on access to the Duostack API and a set of valid user credentials being present (either in `~/.duostack` or provided as environment variables).

Real actions are taken on the platform during test execution. While no user data should be touched, it is recommended that you use a test account whenever running the test scripts. An easy way to do that is to provide `DSUSER` and `DSPASS` environment variables to the test script:

    DSUSER=testuser DSPASS=testpass rake test

If those are not present, the cached credentials in `~/.duostack` will be used (if present), and no tests of credentials syncing can be done.

To run the domain adding/removing test cases, a valid domain name must be provided as an environment variable:

    DSDOMAIN=test.example.com rake test

During the test run, this domain will actually be added then removed from the generated test app, and in order to add it successfully, it must be set up properly (CNAME'd to `proxy.duostack.com`).


Contact
-------

This project is maintained by Duostack, Inc. You can reach us on GitHub (<https://github.com/duostack>) or at support@duostack.com.


License
-------

Copyright © 2011 Duostack, Inc. <http://duostack.com/>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
