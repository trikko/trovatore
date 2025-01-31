/*
MIT License

Copyright (c) 2025 Andrea Fontana

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import std;

// This will be replaced by the version from the build system
enum buildVersion = import("version").chomp;

auto getHomeDirectory()
{
	string home = cast(string)(environment.get("HOME").dup);
	return home;
}

version(linux)
{

	auto getUserDirectories()
	{
		string[] paths;
		if (executeShell("xdg-user-dir").status == 0)
		{
			paths ~= executeShell("xdg-user-dir DOCUMENTS").output.chomp;
			paths ~= executeShell("xdg-user-dir DOWNLOAD").output.chomp;
			paths ~= executeShell("xdg-user-dir MUSIC").output.chomp;
			paths ~= executeShell("xdg-user-dir PICTURES").output.chomp;
			paths ~= executeShell("xdg-user-dir VIDEOS").output.chomp;
			paths ~= executeShell("xdg-user-dir TEMPLATES").output.chomp;
			paths ~= executeShell("xdg-user-dir PUBLICSHARE").output.chomp;
		}

		return paths;
	}

}

version(OSX)
{
	auto getUserDirectories()
	{
		string[] paths;
		string home = getHomeDirectory();

		if (home.length > 0)
		{
			paths ~= home ~ "/Desktop";
			paths ~= home ~ "/Downloads";
			paths ~= home ~ "/Documents";
			paths ~= home ~ "/Music";
			paths ~= home ~ "/Pictures";
			paths ~= home ~ "/Movies";
			paths ~= home ~ "/Sites";
			paths ~= home ~ "/Public";
		}

		return paths;
	}
}

version(linux)
{
	string getConfigDir()
	{
		string home = getHomeDirectory();

		if (home.length > 0)
			return home ~ "/.config/trovatore/";

		return "/etc/trovatore/";
	}
}

version(OSX)
{
	string getConfigDir()
	{
		string home = getHomeDirectory();

		if (home.length > 0)
			return home ~ "/Library/Application Support/trovatore/";

		return "/Library/Application Support/trovatore/";
	}
}

void main(string[] args)
{
	string[][] sources;
	string[] blacklist;

	enum SearchType {
		file,
		dir,
		all
	}

	enum MatchType {
		starts,
		ends,
		contains,
		exact
	}

	SearchType type = SearchType.all;
	MatchType match = MatchType.contains;

	bool skipHidden = true;
	bool enableWildcards = true;
	bool fail = false;

	GetoptResult parsedArgs;

	try
	{
		// Parse arguments using std.getopt
		parsedArgs = getopt(
			args,
			"type|t", &type,
			"enable-wildcards|w", &enableWildcards,
			"match|m", &match,
			"skip-hidden|s", &skipHidden,
		);
	}
	catch (Exception e)
	{
		stderr.writeln("Error parsing arguments.\n");
		fail = true;
	}

	if (!fail &&args.length < 2)
	{
		stderr.writeln("Please provide a target.\n");
		fail = true;
	}

	if (!fail &&parsedArgs.helpWanted)
		fail = true;

	if (fail)
	{
		stderr.writeln("trovatore [", buildVersion, "]\n");
		stderr.writeln("Usage: trovatore [options] <target>");
		stderr.writeln("Options:");
		stderr.writeln("  -t, --type=<file|dir|all>                   Type of search (default: all) ");
		stderr.writeln("  -m, --match=<starts|ends|contains|exact>    Match type (default: contains) ");
		stderr.writeln("  -w, --enable-wildcards=<true|false>         Enable wildcards (default: true) ");
		stderr.writeln("  -s, --skip-hidden=<true|false>              Skip hidden directories (default: true)");
		stderr.writeln("  -h, --help                                  Show help information");
		return;
	}

	// Get config directory
	auto configDir = getConfigDir();

	// Get sources directory
	auto sourcesDir = buildPath(configDir, "sources.d");
	mkdirRecurse(sourcesDir);

	// Get sources
	auto configSources = dirEntries(sourcesDir, SpanMode.shallow, false).array.sort!((a, b) => a.name < b.name).map!(e => e.name).array;

	// If no sources are found, create default sources
	if (configSources.length == 0)
	{
		configSources ~= buildPath(sourcesDir, "00-user");
		std.file.write(configSources[$-1], getUserDirectories().join("\n"));

		configSources ~= buildPath(sourcesDir, "01-home");
		std.file.write(configSources[$-1], getHomeDirectory());

		configSources ~= buildPath(sourcesDir, "02-system");
		std.file.write(configSources[$-1],  ["/opt", "/etc"].join("\n"));

		configSources ~= buildPath(sourcesDir, "99-root");
		std.file.write(configSources[$-1], "/");
	}

	// Add sources from config
	foreach(c; configSources)
	{
		auto lines = c.readText.splitLines.filter!(s => s.length > 0).array;
		sources ~= lines;
	}

	// Add current working directory to sources
	if (sources.length > 0) sources[0] ~= getcwd();
	else sources ~= [getcwd()];

	// Get blacklist
	if (exists(buildPath(configDir, "blacklist")))
	{
		blacklist = buildPath(configDir, "blacklist").readText.splitLines.filter!(s => s.length > 0).array;
	}
	else
	{
		// Default blacklist
		blacklist = [
			"/dev", "/proc", "/sys", "/run", "/mnt", "/snap", "/usr/share/man", "/usr/share/doc", "/var/lib/", "/usr/src", "/etc/firejail",
			".gradle", ".dub", ".npm", "node_modules", "bower_components", ".cargo", ".maven", ".venv", "venv", ".virtualenv", "__pycache__", ".cache", "cache", ".tmp", "tmp", ".git", ".svn", ".github",
			".hg", ".bzr", ".vscode", ".idea", ".eclipse", ".vs", ".atom", ".DS_Store", "__MACOSX", "log", "logs", ".log", "debug", ".thumbnails", ".Trash", ".config", ".local", ".cache", "site-packages", "packages", "extensions", "pkg", "pkgs",
			"modules", "plugins", "plugin", "addons", "dist-packages", "lib-dynload", "cmakefiles", ".deps", ".obj", ".o", "meson-logs", "meson-info", ".ninja_log", ".ninja_build", "autom4ate.cache", ".mozilla"
		];

		std.file.write(buildPath(configDir, "blacklist"), blacklist.join("\n"));
	}

	// Get targets
	auto target = args[1..$].join(" ");

	// Regex expression
	string expr;

	foreach(c; target)
	{
		if (enableWildcards)
		{
			if(c == '*') expr ~= ".*";
			else if(c == '?') expr ~= ".";
			else expr ~= `\x` ~ format("%02x", cast(ubyte)(std.ascii.toLower(c)));
		}
		else expr ~= `\x` ~ format("%02x", cast(ubyte)(std.ascii.toLower(c)));
	}

	expr = "(" ~ expr ~ ")";

	if (match == MatchType.exact) expr = "^" ~ expr ~ "$";
	else if (match == MatchType.starts) expr = "^" ~ expr;
	else if (match == MatchType.ends) expr ~= "$";

	// Compile regex expression
	auto re = regex(expr);

	// Visited directories
	bool[string] visited;

	// Errors
	size_t errors = 0;

	// Path to check
	string[] path;

	// Iterate over sources
	foreach(s; sources)
	{
		path = s.dup;
		size_t current = 0;

		while(current < path.length)
		{
			try {
				// Skip if already visited
				if (path[current] in visited)
				{
					current++;
					continue;
				}

				// Mark as visited
				visited[path[current]] = true;

				// Get directory entries
				auto de = dirEntries(path[current], SpanMode.shallow, false);

				foreach(DirEntry d; de)
				{
					// Skip symlinks
					if (d.isSymlink) continue;

					// Should we recurse into this directory?
					if (d.isDir)
					{
						// Skip hidden directories
						if (skipHidden && d.name.baseName.startsWith(".")) continue;

						// Skip blacklisted directories
						if (blacklist.canFind(d.name)) continue;
						if (blacklist.canFind(d.name.baseName)) continue;

						// Add to path
						if (d.name !in visited)
							path ~= d.name;
					}

					// Skip files if not searching for files
					if (d.isFile && !(type == SearchType.file || type == SearchType.all))
						continue;

					// Skip directories if not searching for directories
					if (d.isDir && !(type == SearchType.dir || type == SearchType.all))
						continue;

					// Get file name
					string name = d.name.baseName.toLower;


					bool found = false;

					foreach(t; target)
					{
						if (name.match(re))
						{
							writeln(d.name);
							found = true;
							break;
						}
					}

				}
			}
			catch (Exception e)
			{
				errors++;
			}

			current++;
		}
	}


}