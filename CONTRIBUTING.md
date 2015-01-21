Contributing to Framework One (FW/1, DI/1)
==
All development happens in the main [Framework One repository](https://github.com/framework-one/fw1) on the **develop** branch. Feel free to fork the repo and submit Pull Requests on the **develop** branch. You can also open issues there to discuss potential enhancements etc.

Pull Requests that contain new/updated tests for the bug fix / enhancement will be looked on more favorably than those that do not contain fixes. Travis-CI automatically runs the test suite for Pull Requests which helps us be confident that the Pull Request is "good".

Look at `run-tests-example.sh` to see how to run tests locally (copy that shell script to `run-tests.sh` - which is ignored by Git - and modify it to match your local setup). You'll need a fair bit of machinery setup for testing!

Please follow the same formatting as the existing code, especially in terms of spacing around operators, parentheses, braces and so on. If in doubt, ask on the mailing list.

The **master** branch represents the current stable release of FW/1. Do not submit Pull Requests against **master**. Showstopping bugs should be raised as issues and fixes will be applied to **develop** (if appropriate) and backported to **master** manually.

**Note:** Do not submit Pull Requests against [Sean's personal fork](https://github.com/seancorfield/fw1) - that exists for historical reasons and Github doesn't let you turn Pull Requests off.
