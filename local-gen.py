#!/bin/python

import sys
import os

FALLBACK_SKIPPED = "<skipped due to previous error>"


def parse(dir="."+os.path.sep):
	"""Produces a pre-filled-with-data, but yet unprocessed (please call .process() on the result, if needed), ParseResult object, based on all the data found in the specified dir (your shell workdir by default)."""
	ram = 0
	world = FALLBACK_SKIPPED
	index = 1
	err = f"Error while reading {dir}_mc_options.txt: "

	try:
		with open(dir+"_mc_options.txt") as f:
			for line in f: 
				if index == 1:
					ram = int(line)
				elif index == 2:
					world = line.strip()
				index += 1
	except Exception as e:
		return ParseResult(ram, world, err+str(e))
	
	if index != 3:
		return ParseResult(ram, world, f"{err}Wrong line count (expected 2, got {index-1})")
	if ram < 1:
		return ParseResult(ram, world, f"{err}RAM value is nonsensical (expected more than 0GB, got {ram})")

	result = ParseResult(ram, world)
	index = 1
	err = f"Error while reading {dir}worlds.csv: "
	try:
		with open(dir+"worlds.csv") as f:
			for line in f:
				parts = line.strip().split(",")
				if len(parts) != 3:
					return ParseResult(ram, world, f"{err}Line #{index} has a wrong number of parts (expected 3, got {len(parts)})")
				elif parts[0] in result.worlds:
					return ParseResult(ram, world, f"{err}Line #{index} has a duplicate world name \"{parts[0]}\"")
				elif parts[0].find("/") != -1:
					return ParseResult(ram, world, f"{err}Line #{index} has an illegal world name \"{parts[0]}\"")
				else:
					result.worlds[parts[0]] = World(parts[1], parts[2])
				index += 1
	except Exception as e:
		return ParseResult(ram, world, err+str(e))
	
	err = f"Error while reading {dir}instances{os.path.sep}"
	try:
		for instance in os.listdir(dir+"instances"):
			if not os.path.isdir(dir+"instances"+os.path.sep+instance):
				continue
			java = None
			modpack = None
			index = 1
			suberr = f"{err}{instance}{os.path.sep}_mc_options.txt: "
			try:
				with open(dir+"instances"+os.path.sep+instance+os.path.sep+"_mc_options.txt") as f:
					for line in f: 
						if index == 1:
							java = line.strip()
						elif index == 2:
							modpack = line.strip()
						index += 1
				if index != 3:
					return ParseResult(ram, world, f"{suberr}Wrong line count (expected 2, got {index-1})")
				else:
					result.instances[instance] = Instance(modpack, java)
			except Exception as e:
				return ParseResult(ram, world, suberr+str(e))
	except Exception as e:
		return ParseResult(ram, world, err+": "+str(e))
	
	return result

class ParseResult:
	"""A hybrid between a result-carrier class for the parse() function, and a simple way to store _mc_options.txt in a deserialized form (if you don't populate it with any extra data (which is what parse() does) beyond what the constructor wants)."""
	DEFAULT_INVALIDITY_REASON = "Data not processed yet. If seen in prod, there's a bug."
	NO_INVALIDITY_REASON = None

	def __init__(self, options_ram: int, options_world_name: str, parse_invalidity_reason=DEFAULT_INVALIDITY_REASON):
		FALLBACK_UNPROCESSED = "<data not yet processed>"

		self.worlds = {}
		self.instances = {}
		self.options_ram = options_ram
		self.options_world_name = options_world_name
		self.processed_world = World(FALLBACK_UNPROCESSED, FALLBACK_UNPROCESSED)
		self.processed_world_instance = Instance(FALLBACK_UNPROCESSED, FALLBACK_UNPROCESSED)
		self.parse_invalidity_reason = parse_invalidity_reason
	
	def process(self):
		"""Populates the internal World and Instance objects."""
		FALLBACK_NOTFOUND = "<not found>"
		
		if self.parse_invalidity_reason != self.DEFAULT_INVALIDITY_REASON and self.parse_invalidity_reason != self.NO_INVALIDITY_REASON:
			self.processed_world = World(FALLBACK_SKIPPED, FALLBACK_SKIPPED)
			self.processed_world_instance = Instance(FALLBACK_SKIPPED, FALLBACK_SKIPPED)
			return self
		
		if self.options_world_name not in self.worlds:
			self.parse_invalidity_reason = f"World \"{self.options_world_name}\" not found in worlds.csv"
			self.processed_world_instance = Instance(FALLBACK_SKIPPED, FALLBACK_SKIPPED)
			self.processed_world = World(FALLBACK_NOTFOUND, FALLBACK_NOTFOUND)
			return self
		self.processed_world = self.worlds[self.options_world_name]
		
		if self.processed_world.instance_name not in self.instances:
			self.parse_invalidity_reason = f"World \"{self.options_world_name}\" runs on instance \"{self.processed_world.instance_name}\", which was not found in instances/"
			self.processed_world_instance = Instance(FALLBACK_NOTFOUND, FALLBACK_NOTFOUND)
			return self
		self.processed_world_instance = self.instances[self.processed_world.instance_name]

		self.parse_invalidity_reason = self.NO_INVALIDITY_REASON
		return self
	
	def digest(self):
		"""Produces a short string that at-a-glance describes all the data present withing this class. Think of it as a human-readable hash. Notably, None will be outputted instead, if the data stored here is in any way invalid, which means that calling "if <object name>.digest():" can serve as a validity check, eliminating the need for any .is_valid() function."""
		if self.parse_invalidity_reason == self.NO_INVALIDITY_REASON:
			return f"{self.options_world_name} ({self.processed_world.inner_name} in {self.processed_world.instance_name}@{self.processed_world_instance.modpack}) @ {self.processed_world_instance.java} with {self.options_ram}GB RAM"
	
	def print_opt(self):
		"""prints the stored deserialized _mc_options.txt contents"""
		print("LOADED OPTIONS:")
		print("-> RAM GBs:", self.options_ram)
		print("-> WORLD:", self.options_world_name)
		print("|-> INNER NAME:", self.processed_world.inner_name)
		print("\\-> INSTANCE:", self.processed_world.instance_name)
		print(" |-> MODPACK:", self.processed_world_instance.modpack)
		print(" \\-> JAVA IMAGE:", self.processed_world_instance.java)
		print("-> STATUS:", f"Valid with digest: {self.digest()}" if self.digest() else f"Invalid because: {self.parse_invalidity_reason}")
	
	def print_all(self):
		"""prints all stored data"""
		print("WORLDS:")
		ran = False
		for instance in self.worlds.items():
			ran = True
			print("->", instance[0])
			print("|-> INNER NAME:", instance[1].inner_name)
			print("\\-> INSTANCE:", instance[1].instance_name)
		if not ran:
			if self.parse_invalidity_reason == self.NO_INVALIDITY_REASON:
				print("-> <no worlds found>")
			else:
				print("-> <no worlds found, or the data was so invalid, that they couldn't even be searched for>")
		print()

		print("INSTANCES:")
		ran = False
		for instance in self.instances.items():
			ran = True
			print("->", instance[0])
			print("|-> MODPACK:", instance[1].modpack)
			print("\\-> JAVA IMAGE:", instance[1].java)
		if not ran:
			if self.parse_invalidity_reason == self.NO_INVALIDITY_REASON:
				print("-> <no instances found>")
			else:
				print("-> <no instances found, or the data was so invalid, that they couldn't even be searched for>")
		print()

		self.print_opt()

class World:
	"""Stores the description of a world. Notably, it's a DESCRIPTION OF, not a REFERENCE TO it, which means that it stores the data within the world definition (instance and inner name), but not the name of the world definition (1st column of worlds.csv) itself."""
	def __init__(self, instance_name: str, inner_name: str):
		self.instance_name = instance_name
		self.inner_name = inner_name

class Instance:
	"""Stores the description of an instance. Notably, it's a DESCRIPTION OF, not a REFERENCE TO it, which means that it stores the data within the instance's _mc_options.txt (Java and modpack), but not the name of the instance definition (folder) itself."""
	def __init__(self, modpack: str, java: str):
		self.modpack = modpack
		self.java = java


def compare(parsed: ParseResult|None=None, dir="."+os.path.sep):
	"""Produces a CompareResult object. All the comparisons are done in the specified dir (your shell's workdir by default) and you can also pass a pre-cached processed ParseResult object if you already have one, so that it doesn't have to construct and process a new one."""
	loaded:str|None = None
	try:
		with open(dir+"_mc_hist.txt") as f:
			for line in f:
				# Always the last line is loaded as the actual digest - lets us have a simple history system
				loaded = line.strip()
	except:
		pass
	
	compose:str|None = None
	try:
		with open(dir+"compose.yml") as f:
			for line in f:
				if line.find("      LAUNCHED_WITH_DIGEST: \"") != -1:
					compose = line.strip()
					break
	except:
		pass
	
	return CompareResult(parsed.digest() if parsed else parse(dir).process().digest(), compose, loaded)

class CompareResult:
	"""A result-carrier class for the compare() function. What's stored inside is kinda useless on its own (just 3 digest strings), but you also get 8 booleanish (except one) interrogation-functions about this data, that let you get a clear picture of what's running what, and whether it's running what's actually supposed to."""
	def __init__(self, digest_options: str|None, digestline_compose: str|None, digest_loaded: str|None):
		self.digest_options = digest_options
		self.digestline_compose = digestline_compose
		self.digest_loaded = digest_loaded
	
	def should_compose_have_mc(self):
		"""Whether your Options are valid (ie. whether we want a Minecraft container in compose, or not)."""
		return bool(self.digest_options)
	
	def does_compose_have_mc(self):
		"""Whether you have a Minecraft container in compose, or not."""
		return bool(self.digestline_compose)
	
	def could_compose_match_options(self):
		"""Whether it's even POSSIBLE for Compose's and Options' content to agree on the state of the Minecraft container - that is, to say, do they at least agree that it should exist. If this is false, regen your Compose."""
		return self.should_compose_have_mc() == self.does_compose_have_mc()
	
	def does_compose_match_options(self):
		"""Whether Compose's and Options' content agree on the state of the Minecraft container - that is, to say, if they both think that it should exist (if not, this passes-through the output from could_compose_match_options()), do they also agree on what it should be running (the global world name (and all its consequences) and the RAM size)."""
		if self.should_compose_have_mc() and self.does_compose_have_mc():
			return self.digestline_compose.find(self.digest_options) > -1
		else:
			return self.could_compose_match_options()
	
	def has_mc_been_run_at_least_once(self):
		"""If there exists at least a single line in _mc_hist.txt - which would indicate that the server must've been launched at least once."""
		return bool(self.digest_loaded)
	
	def should_mc_have_been_ran_at_least_once(self):
		"""THE ONE NON-BOOLEANISH FUNCTION IN THIS CLASS! Well... It is booleanish, in the sense that its outputs can be read as a True/False value - except that this one always returns truthy ones (which actually makes some logical sense, if you thing about it - read 'till the end). More specifically, it returns a non-empty string that describes what Options and Compose think about whether the Minecraft container should've been ran at lest once. We opted to return strings because there is no way to answer this question without any assumptions, because it's IMPOSSIBLE to know if MC should've been ran at least once - that'd mean knowing if Options were valid at any point in time ever, and we can't exactly time-travel. This is why even the „falsiest” of all results (NOT_NOW__PAST_CONDITIONS_UNKNOWN) isn't really an outright No!, but an „Eh, maybe...?” at most. However, some heuristics may point at the past state - notably, if the Compose says that there is an MC container, then Options must've wanted one at some point in the past, too (regardless of what they say now). But simply treating this as True for the sake of being pedantic is wildly impractical because Options are the main Source of Truth and most consumers of this methods wouldn't want to have them just disregarded like that. So overall, instead of trying to find a shaky middle-ground, you get a string output and can interpret it however you wish. (Also, when you think about it, always outputting truthy values (ie. non-empty strings) makes a lot of sense, given how this project is specifically for Minecraft servers, so it's EXTREMELY likely that a Minecraft server was, at some point supposed to be running.)"""
		if self.should_compose_have_mc() and self.does_compose_have_mc():
			return "DEFINITELY"
		elif not self.should_compose_have_mc() and not self.does_compose_have_mc():
			return "NOT_NOW__PAST_CONDITIONS_UNKNOWN"
		elif self.should_compose_have_mc():
			return "COMPOSE_REGEN_NEEDED__YES_BY_OPTIONS__NOT_NOW_BY_COMPOSE"
		else:
			return "COMPOSE_REGEN_NEEDED__NOT_NOW_BY_OPTIONS__YES_BY_COMPOSE"
	
	def should_mc_have_been_ran_at_least_once_NAIVE(self):
		"""A naïve way of booleanishly interpreting should_mc_have_been_ran_at_least_once()'s result, ie. assumes that Options are out main Source of Truth and ignores any hints at „MC shouldn't be running now, but likely was supposed to be ran at least once, actually”. In other words, this function basically tells you if Options want MC running, right here and now, despite its name hinting at some level of past-state analysis."""
		return self.should_mc_have_been_ran_at_least_once() == "DEFINITELY" or self.should_mc_have_been_ran_at_least_once() == "COMPOSE_REGEN_NEEDED__YES_BY_OPTIONS__NOT_NOW_BY_COMPOSE"

	def should_mc_have_been_ran_at_least_once_PEDANTIC(self):
		"""An impractically pedantic way of booleanishly interpreting should_mc_have_been_ran_at_least_once()'s result, ie. if ANYTHING signals that MC should've been ran once, we return True. If there's nothing indicating that, we return None (falsy, but not outright a False) because can you REALLY be sure that nothing wanted it running at any point in time?"""
		if self.should_mc_have_been_ran_at_least_once() == "NOT_NOW__PAST_CONDITIONS_UNKNOWN":
			return None
		else:
			return True

	def is_mc_running_what_its_supposed_to(self):
		"""Attempts to answer the super-hard question of „Is Minecraft running when it's supposed to? If so, is it running what it's supposed to?”. Said question is super hard because it's impossible to truly know whether MC is running (only that it was launched at least once, but the process may be long dead), as far as this script is concerned (it doesn't integrate with Compose (to avoid conflicts with any management system it may become a part of, eg. JifoCC) so it can't just run a healthcheck). Also, „what it's supposed to” is a somewhat difficult question because technically a container is running what it's supposed to, if it aligns with its Compose definition - but in our case, the Compose definition can also (mis)align with the Options. ANYWAY, if you approach this in the most naïve way possible (ie. if Minecraft was launched at any point in time, then assume it's still running now; disregard Compose and compare straight to Options), then treating this function's output booleanishly is gonna be fine. Truthy means that your MC container aligns with options and there's no need to stop+rebuild+start it (tho it does NOT say anything about Compose or non-restarts, ie. „start” without „stop” or „stop+rebuild”) and Falsy means „Some attention may be needed” (whether that's simply rebuild+start, stop+rebuild+start, stop+regen+rebuild+start, simply stop, or a false alarm - it doesn't matter in this naïve case). For a more detailed breakdown of what this function's booleanish-but-not-boolean returns (None and various literals) mean, and how to act upon them, see code comments at each specific return or how we interpret the results in the Compare subcommand."""
		if self.does_compose_match_options():
			if self.digest_options != None:
				return self.digest_loaded == self.digest_options #True? Yay, it's running what it's supposed to! False? It's fine, a valid Compose is waiting for you - just rebuild the container.
			elif self.digest_options == None and not self.has_mc_been_run_at_least_once():
				return True #Same deal as above (except in this case, it's more like „It's NOT running - which is indeed what it's supposed to be not-doing.”)
			else:
				return None #No answer possible: We know that MC shouldn't be running NOW (according to the Compose file and the Options), and that it WAS LAUNCHED in the past, but we don't know if it's  still running right now.
		elif self.digest_loaded == self.digest_options:
			return "COMPOSE_LAGGING_BEHIND" #The value is still truthy because it IS running what is supposed to (or isn't supposed to be running, and indeed was never launched), according to the Options (which are our main Source of Truth), but we're not giving an outright True because this is the „danger zone” (if a container rebuild happens, it will load a wrong definition from the Compose file) and so we want to signal it.
		elif self.digest_options == None:
			return None #No answer possible: We know that MC shouldn't be running NOW (according to the Options - not according to Compose because it's lagging behind options, but that's not our main Source of Truth so we disregard its opinion, just like above (tho unlike above, you don't get any cool warnings because there is no way to make a falsy text except leaving it blank)), and that it WAS LAUNCHED in the past, but we don't know if it's still running right now.
		else:
			return 0 ##Either your Compose file is lagging behind Options and MC is currently running from it (or was launched from it and isn't running anymore), or your Compose file is lagging behind Options AND ALSO your MC is lagging behind that still (creating some weird 3-way state desync clusterfuck). In either case, MC is definitely not running what it's supposed to, so a falsy value gets returned. It's a zero and not outright False, tho, to signify that extra steps must be taken to resolve this: You need to regen the Compose file and then rebulid your Minecraft container from it (as opposed to simply rebuilding the container, like you'd do upon encountering a regular False as the return value).


def build(parsed: ParseResult|None=None, dir="."+os.path.sep):
	"""Outputs a compose.yml to the specified dir (your shell's workdir by default), based on the templates found in that dir's _internal dir and a processed ParseResult object inputted. If you don't pass in any ParseResult object, or they're in any way unprocessed/invalid, then the resulting compose.yml will omit Minecraft (and this function will return False, as opposed to True if Minecraft were included)."""
	lines = []
	result = False
	with open(dir+"_internal"+os.path.sep+"compose-template-header.yml") as f:
		for line in f: 
			lines.append(line.replace(" ", "{{SPC}}").strip())
	if parsed and parsed.digest():
		result = True
		with open(dir+"_internal"+os.path.sep+"compose-template-mc.yml") as f:
			for line in f:
				lines.append(line
					.replace("{{WORLD_INSTANCE_IMAGE_VERSION}}", parsed.processed_world_instance.java)
					.replace("{{WORLD_INSTANCE_DIR}}", parsed.processed_world.instance_name)
					.replace("{{WORLD_INSTANCE_MODPACK}}", parsed.processed_world_instance.modpack)
					.replace("{{RAM_ALLOCATION}}", str(parsed.options_ram))
					.replace("{{WORLD_NAME_INNER}}", parsed.processed_world.inner_name)
					.replace("{{DIGEST}}", parsed.digest())
					.replace("{{WORLD_NAME}}", parsed.options_world_name)
					.replace(" ", "{{SPC}}").strip()
				)
	with open(dir+"_internal"+os.path.sep+"compose-template-footer.yml") as f:
		for line in f: 
			lines.append(line.replace(" ", "{{SPC}}").strip())
	with open("compose.yml", 'w') as f:
		f.write("\n".join(lines).replace("{{SPC}}", " "))
	return result


if __name__ == "__main__":
	if len(sys.argv) > 2:
		print("Expected at most 1 extra argument!")
		exit(1)

	parsed = parse().process()

	if len(sys.argv) == 1:
		parsed.print_all()
		print()
		print("WHAT TO DO WITH ALL OF THIS:")
		print("->", sys.argv[0], "stats")
		print("|-> Prints out a shellscript that will generate a statsdir for all the worlds above.")
		print("|")
		print("|-> If a given world (or even its instance) no longer exists, but it still has an entry (please DO keep such")
		print("|-> entries, actually - to prevent conflicts in stat-tracker names), Linux's `cp` in that shellscript will")
		print("\\-> simply warn you and move on. So, again, DO keep removed entires - not only is it safe, it's actually better.")
		print("->", sys.argv[0], "compose")
		print("|-> Generates a Docker Compose file for the Minecraft server, according to the loaded options above.")
		print("|")
		print("|-> If aforementioned options are invalid, the Minecraft server part will be omitted")
		print("\\-> and you'll only get auxiliary Docker services, like the webserver or the database.")
		print("->", sys.argv[0], "compare")
		print("\\-> 3-way comparison between your options (above), what Compose says, and what's actually running.")

	elif sys.argv[1] == "stats":
		print("rm -vr \"./stats_export\";")
		print("mkdir -p \"./stats_export\";")
		ran=False
		for world in parsed.worlds.items():
			ran=True
			print(f"cp -vr \"./instances/{world[1].instance_name}/{world[1].inner_name}/stats\" \"./stats_export/{world[0]}\";")
		if not ran:
			print("echo \"WARN! It seems like you don't have worlds. If that's true - fine! I don't know WHY you'd do that, but sure.\";")

	elif sys.argv[1] == "compose":
		try:
			if build(parsed):
				print("WARNING: GENERATED OUTPUT CONTAINS A MINECRAFT SERVER COMPOSE DEFINITION, THAT COMES WITH THE EULA PRE-APPROVED. BY LAUNCHING THAT SERVER VIA THE MEANS SPECIFIED BELOW, OR ANY OTHER MEANS, YOU HERBY COMPLY WITH BOTH MOJANG EULAS AVAILABLE AT https://aka.ms/MCUGEULA AND https://aka.ms/MCUsageGuidelines AS WELL AS MICROSOFT TOS AT https://www.microsoft.com/servicesagreement - IF YOU DO NOT WISH TO COMPLY WITH ANY OF THE SPECIFIED DOCUMENTS, PLEASE REGENERATE YOUR COMPOSE DEFINITION WITHOUT THE MINECRAFT COMPONENT, BEFORE RUNNING IT FOR THE FIRST TIME!")
			print("Generated! (Re)build and run the container with \"docker compose up -d\" or via your management system (eg. JifoCC if on GhostLand).")
		except Exception as e:
			print(f"Something went wrong: {e}")


	elif sys.argv[1] == "compare":
		comp = compare(parsed)
		parsed.print_opt()
		print("\\-> WHICH MEANS:", "The Compose file should contain MC, and it should be running with the digest above." if comp.should_compose_have_mc() else "The Compose file shouldn't mention MC, and MC shouldn't be running.")
		print()
		print("COMPOSE FILE:")
		print("->", f"CONTAINS LINE: \"{comp.digestline_compose}\"" if comp.does_compose_have_mc() else "Doesn't include the MC container (or doesn't even exist at all).")
		print("\\-> ...Which means that it", "ALIGNS" if comp.does_compose_match_options() else "DOES NOT align", "with what Options above want.", "No regen needed." if comp.does_compose_match_options() else "Please regen it.")
		print()
		print("MINECRAFT SERVER:")
		if comp.has_mc_been_run_at_least_once():
			print("-> Was launched at min. once and MAYBE is still running (this command only checks launch hist.)")
			if comp.should_mc_have_been_ran_at_least_once_NAIVE():
				print("\\-> But I'd hope it is because it SHOULD be, according to Options", "and Compose." if comp.should_mc_have_been_ran_at_least_once() == "DEFINITELY" else "- but not Compose (pls regen! - and then start, if needed).")
			else:
				print("\\-> But I'd hope it isn't because it SHOULDN'T be, according to Options", "and Compose." if comp.should_mc_have_been_ran_at_least_once() == "NOT_NOW__PAST_CONDITIONS_UNKNOWN" else "- but not Compose (pls regen! - and stop the container, if needed).")
			print("-> MOST RECENT LAUNCH'S DIGEST:", comp.digest_loaded)
			if comp.is_mc_running_what_its_supposed_to():
				print("\\-> Which aligns with your Options", "- but somehow not your Compose (pls regen! - tho you WON'T need to rebuild the container)." if comp.is_mc_running_what_its_supposed_to() == "COMPOSE_LAGGING_BEHIND" else "and your Compose. All good!")
			elif comp.is_mc_running_what_its_supposed_to() != None:
				print("\\-> Which doesn't align with your Options. :<")
			else:
				pass # If comp.is_mc_running_what_its_supposed_to()==None, the digest is irrelevant, so we make no comments about it.
		else:
			print("-> Was never launched.")
			match comp.should_mc_have_been_ran_at_least_once():
				case "NOT_NOW__PAST_CONDITIONS_UNKNOWN":
					print("\\->Which is good. Both your Options and Compose don't want it running rn. If it was never even launched, it sure as hell isn't running now.")
				case "COMPOSE_REGEN_NEEDED__NOT_NOW_BY_OPTIONS__YES_BY_COMPOSE":
					print("|->Which is odd. Your Options don't want it running rn (which is good - if it was never even launched, it sure as hell isn't running now).")
					print("|->The same cannot be said about your Compose, tho. And if that wants MC to be launched, that means that it was supposed to be running.")
					print("\\->...Oh, well! Doesn't matter now - just regen the Compose and don't dwell on the past too much.")
				case _:
					print("\\->Which is bad! Your Options", "and Compose" if comp.could_compose_match_options() else "(not Compose tho)" ,"want it running (which cannot be happening if it wasn't even launched). So build the container and FLOOR IT!")
					if not comp.does_compose_match_options():
						print(" \\-> But regen your Compose first!", "Apparently, it's a bit outdated." if comp.does_compose_have_mc() else "As said above, it doesn't even KNOW that your Options want MC running.")
		print()
		print("TO SUMMARIZE:")
		print("-> OPTIONS WANT DIGEST:", parsed.digest() if comp.should_compose_have_mc() else "[NONE] - They don't even want MC running.")
		print("-> DOES COMPOSE MATCH THAT:", "Yes!" if comp.does_compose_match_options() else "No - please regen it!")
		if comp.should_mc_have_been_ran_at_least_once_NAIVE():
			print("-> MC CONTAINER:", "Is running exactly what it's supposed to (unless it's not running at all)! Don't rebuild it (launch it, at most - if not running)." if comp.is_mc_running_what_its_supposed_to() else "May require some attention. See above for details.")
			if comp.is_mc_running_what_its_supposed_to() == "COMPOSE_LAGGING_BEHIND":
				print("|-> Yes, don't rebuild it, EVEN AFTER the Compose regen. Apparently, only Compose is lagging behind and MC is somehow already running whatever your Options want.")
				print("\\-> Unless it's not running at all. That'd explain this weird \"leap-frogged desync\". Please rebuild it before launching, then - just to be sure.")
		else:
			print("-> MC CONTAINER SHOULDN'T BE RUNNING:", "So make sure it is in fact stopped (we can't determine that from here)." if comp.has_mc_been_run_at_least_once() else "...And it was never even launched, so it indeed isn't. Great!" )

	else:
		print("Unknown subcommand", sys.argv[1])
		exit(1)
	
	exit(0)