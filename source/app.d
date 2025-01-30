import std;
import consolecolors;

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
			paths ~= executeShell("xdg-user-dir").output.chomp;
		}
		else
		{
			string home = environment.get("HOME");

			if (home.length > 0)
				paths ~= home;

		}

		return paths;
	}

}

version(osx)
{
	auto getUserDirectories()
	{
		string home = environment.get("HOME");

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
			paths ~= home;
		}

		return paths;
	}
}

version(linux)
{
	string getConfigDir()
	{
		string home = environment.get("HOME");

		if (home.length > 0)
			return home ~ "/.config/trovatore/";

		return "/etc/trovatore/";
	}
}

version(osx)
{
	string getConfigDir()
	{
		string home = environment.get("HOME");

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

	SearchType type = SearchType.all;
	bool fail = false;

	GetoptResult parsedArgs;

	try
	{
		// Parse arguments using std.getopt
		parsedArgs = getopt(
			args,
			"type|t", &type,
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
		stderr.writeln("Usage: trovatore [options] <target>");
		stderr.writeln("Options:");
		stderr.writeln("  -t, --type <file|dir|all>  	Type of search (default: all) ");
		stderr.writeln("  -h, --help         			Show help information");
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

		configSources ~= buildPath(sourcesDir, "01-system");
		std.file.write(configSources[$-1],  ["/opt", "/etc"].join("\n"));

		configSources ~= buildPath(sourcesDir, "02-root");
		std.file.write(configSources[$-1],  ["/"].join("\n"));
	}

	// Add current working directory to sources
	sources ~= [getcwd()];

	// Add sources from config
	foreach(c; configSources)
	{
		auto lines = c.readText.splitLines.filter!(s => s.length > 0).array;
		sources ~= lines;
	}

	// Get blacklist
	if (exists(buildPath(configDir, "blacklist")))
	{
		blacklist = buildPath(configDir, "blacklist").readText.splitLines.filter!(s => s.length > 0).array;
	}
	else
	{
		// Default blacklist
		blacklist = [
			"/dev", "/proc", "/sys", "/run", "/mnt", "/snap", "/usr/share/man", "/usr/share/doc", "/var/lib/dpkg", "/var/lib/apt", "/var/lib/pacman", "/var/lib/rpm", "/usr/src", "/etc/firejail",
			".gradle", ".dub", ".npm", "node_modules", "bower_components", ".cargo", ".maven", ".venv", "venv", ".virtualenv", "__pycache__", ".cache", "cache", ".tmp", "tmp", ".git", ".svn",
			".hg", ".bzr", ".vscode", ".idea", ".eclipse", ".vs", ".atom", ".DS_Store", "__MACOSX", "log", "logs", ".log", "debug", ".thumbnails", ".Trash", ".config", ".local", ".cache", "site-packages", "packages", "extensions", "pkg", "pkgs",
			"modules", "plugins", "plugin", "addons", "dist-packages", "lib-dynload", "cmakefiles", ".deps", ".obj", ".o", "meson-logs", "meson-info", ".ninja_log", ".ninja_build", "autom4ate.cache", ".mozilla"
		];

		std.file.write(buildPath(configDir, "blacklist"), blacklist.join("\n"));
	}

	// Get targets
	auto target = args[1..$];

	// Regex expression
	string expr;

	foreach(t; target)
	{
		string s;

		if (expr.length > 0) expr ~= "|";

		foreach(c; t)
		{
			if(c == '*') s ~= ".*";
			else s ~= `\x` ~ format("%02x", cast(ubyte)(std.ascii.toLower(c)));
		}

		expr ~= "(" ~ s ~ ")";
	}

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
						// Exact match
						if (name == t)
						{
							cwriteln("<white>[M]</white> ", escapeCCL(d.name));
							found = true;
							break;
						}

						// Starts with
						else if (name.startsWith(t))
						{
							cwriteln("<white>[S]</white> ", escapeCCL(d.name));
							found = true;
							break;
						}

						// Ends with
						else if (name.endsWith(t))
						{
							cwriteln("<white>[E]</white> ", escapeCCL(d.name));
							found = true;
							break;
						}

						// Contains
						else if (name.canFind(t))
						{
							cwriteln("<white>[C]</white> ", escapeCCL(d.name));
							found = true;
							break;
						}
					}

					// Regex match
					if (!found && name.match(re))
					{
						cwriteln("<white>[W]</white> ", escapeCCL(d.name));
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