/**
	Pseudo generator to output build descriptions.

	Copyright: © 2015 rejectedsoftware e.K.
	License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
	Authors: Sönke Ludwig
*/
module dub.generators.targetdescription;

import dub.compilers.buildsettings;
import dub.compilers.compiler;
import dub.compilers.utils : getTargetFileName;
import dub.description;
import dub.generators.generator;
import dub.internal.vibecompat.inet.path;
import dub.project;

class TargetDescriptionGenerator : ProjectGenerator {
	TargetDescription[] targetDescriptions;
	size_t[string] targetDescriptionLookup;

	this(Project project)
	{
		super(project);
	}

	protected override void generateTargets(GeneratorSettings settings, in TargetInfo[string] targets)
	{
		import std.algorithm : map;
		import std.array : array;

		auto configs = m_project.getPackageConfigs(settings.platform, settings.config);
		targetDescriptions.length = targets.length;
		size_t i = 0;

		bool[string] visited;
		void visitTargetRec(string target)
		{
			if (target in visited) return;
			visited[target] = true;

			auto ti = targets[target];

			TargetDescription d;
			d.rootPackage = ti.pack.name;
			d.packages = ti.packages.map!(p => p.name).array;
			d.rootConfiguration = ti.config;
			d.buildSettings = ti.buildSettings.dup;
			d.dependencies = ti.dependencies.dup;
			d.linkDependencies = ti.linkDependencies.dup;

			// Add static library dependencies
			foreach (ld; ti.linkDependencies) {
				auto ltarget = targets[ld];
				auto ltbs = ltarget.buildSettings;
				auto targetfil = (Path(ltbs.targetPath) ~ getTargetFileName(ltbs, settings.platform)).toNativeString();
				d.buildSettings.addLinkerFiles(targetfil);
			}

			targetDescriptionLookup[d.rootPackage] = i;
			targetDescriptions[i++] = d;

			foreach (dep; ti.dependencies)
				visitTargetRec(dep);
		}
		visitTargetRec(m_project.rootPackage.name);
	}
}
