bundler_ext
===========

Simple library leveraging the Bundler Gemfile DSL to load gems already
on the system and those managed by the systems package manager
(like yum/apt/homebrew/other).

### API ###

- BundlerExt#system_require is analogous to
  [Bundler#require](https://rubydoc.info/gems/bundler/Bundler.require)
  and will auto-require the gems loaded in the Gemfile wherever they
  are installed / can be found.
  
  
- BundlerExt#system_setup is analogous to
  [Bundler#setup](https://bundler.io/guides/bundler_setup.html)
  and will setup the Ruby LOAD_PATH to only incorporate the gemfile
  dependency include paths wherever they are installed.
  

- If either case if the BEXT_ACTIVATE_VERSIONS env var is set true,
  the specific versions of the gem installed via yum/apt/other will be
  detected and activated.

- Specify the BEXT_GROUPS env var to insert additional groups to be loaded
  (separated by whitespace, eg BEXT_GROUPS='group1 group2 ...')

- Specify BEXT_NOSTRICT to disable fail-on-error, otherwise BundlerExt will
  raise a critical error if a dependency fails to load. If set true, BundlerExt
  will simply print the msg to stdout and continue on.

### Show Me The Code! ##

Assuming gemfile_in is defined as

    gemfile_in = File.expand_path('../../Gemfile.in', __FILE__)

To load & require ALL Gemfile groups, use the following statement:

    BundlerExt.system_require(gemfile_in, :all)

To load only the default one, use:

    BundlerExt.system_require(gemfile_in, :default)

BundlerExt#system_require function takes a list of parameters corresponding to all the
environments the invoker intends to use.

To require the default group and the group specified
by the Rails environment, use:
    
    BundlerExt.system_require(gemfile_in, :default, Rails.env)

To setup the LOAD_PATH to only reference the default Gemfile deps:

    BundlerExt.system_setup(gemfile_in, :default)

And so on....

### Other Considerations ###

You may want to wrap your call in some kind of check, to allow
non-platform users to still use bundler if they want to.

One way to accomplish this would be to simply change the name of
the Gemfile for native package system scenarios, eg

    mv Gemfile Gemfile.in

Then, just look for a Gemfile, otherwise, load deps via Gemfile.in/BundlerExt.

Some rubygems require HOME environment variable to be set, threfore
not running daemonized. For this purposes there is BEXT_HOME
variable which can be used to set HOME environment variable before
any rubygem gets loaded. The variable is not exported for
subprocesses.

### License  ###

bundler_ext is licensed under the MIT Licence.

* http://www.opensource.org/licenses/MIT
