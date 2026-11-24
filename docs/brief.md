Silica is designed to be the workspace that holds projects. Think if silica as a primary company product. Its repository should be placed in the following repository: https://github.com/adam3141/silica

I need several projects to be created
1. agate
2. flint
3. opal

These should all be submodules within silica

Agate will be the user interface library that will support opal. Agate should be placed in the following repository: https://github.com/adam3141/agate

Flint is a foundational library that supports both opal and agate. Flint should be placed in the following repository: https://github.com/adam3141/flint

Opal will be an graphical based editor that will be used as my primary programming editor. Opal should be placed in the following directory: https://github.com/adam3141/opal

I would like you to work on agate and flint first. There is a coding-style.md file in docs/architecture that I would like you to follow.

My host will not have the necessary tools and packaged needed to support the development but I will need at the very minimum the following:

1. A development container based on Microsoft's ubuntu 26.04 container image. This will provide the vscode non-root user
2. I will require gcc 16 because of the reflection requirements. Please install the latest that the repository offers.
3. I will need to install the latest versions of clangd, clang-tidy and clang-format
4. I will need to install the following additional extensions in the dev container: llvm-vs-code-extensions.vscode-clangd, Anthropic.claude-code
5. I need the C/C++ extension to disable the Intellisense engine because I will be using clangd
6. Agate will be using SDL3 and OpenGL (at least for now)
7. I will want to be able to run GUI applications from the container
8. Please install any additional packages that you might need so that you can "see" and interact with the user interface

In time, I would like everything to be cross platform. This includes the OS and the graphics library so keep this in mind when developing the library.

Ok. For agate, this will be a user interface library that will have the following features:
- XML based layout: The user interface should be able to be composed using XML, very similar to Microsoft's Xaml that is used in WPF
- Styles: Each control should be able to have a control template which describes how a control looks.
- Animations: The control styles should also include descriptions of what happens when certain events are triggered. For example, a hover onto the control might cause it to glow. For a toggle switch click, it might animate the movement of the solid circle from one position to another.
- Dependency Properties: These would be very useful for two-way data binding.
- Panels: This is where controls can be added to compose the user interface.

Look into WPF because this is exactly what I would like to replicate for my user interface. I think with the benefit of static reflection that C++26 has to offer, this might make it a bit easier.

Remember to put non UI specific functionality into the flint library because this might be used for

I would also like the UI to support themes and have it dynamic so that all I need to do is call a top level function like for example. ApplyTheme(...);

For themes, I would like some out-of-the-box themes, both dark and light based with the themes named by minerals, eg. Topaz, Ruby, Agate, Opal, Malachite, etc...

Please start with Agate and Flint and at various points, please create a demonstration that I can run and give some feedback on what works and what doesn't. What I like and what can be improved.

After the user interface has been worked out, we can then move onto Opal.

Please also create a CLAUDE.md file in the root directory so that future sessions are able to understand where you are up to. Create a TASKS.md file in each repository so that work can be tracked.

Please also write architecture documents for everything and also create API documentation so that I know how to use it and when Opal is being designed, you can refer to it to understand what to do.

Please maintain an ADR register for each library as well.

Ask questions - perhaps not all at once but several at a time so that I am not overwhelmed. I would rather that you not guess at what I want so that we don't have to undo a lot of code later on.

Please ensure the UI is fluid and fast. If you need to, create some benchmarking utilities (this can go into the flint library) to benchmark the UI. I know tracy is very good as well because it has a rich user interface and real time logging of benchmarking information.

Please create a logger (also to go into the flint library) that has several different sinks. Console, File and Network. The Console sink should support ANSI colours. The logger should be able to support the standard set of log levels, i.e. Fatal, Error, Warning, Info, Debug and Trace but I find one thing that is lacking with most loggers I come across are custom levels such that I can filter them. ie. Maybe in the logging configuration file, a custom list. This is something that doesn't need to be decided yet.

The logger should be able to log the source file the log message came from, the line number, the function(not mangled). Should be able to log the time and date, the uptime of the machine but also the uptime of the application, this could be when the Logger was first instantiated.

I would like to be able to log into a Json file as this would better support machine readability.
