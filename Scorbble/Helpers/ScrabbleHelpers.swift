//
//  ScrabbleHelpers.swift
//  Scorbble
//
//  Created by Kieran James on 07.12.25.
//

import Foundation

/// Helper functions for Scrabble scoring and word validation

// MARK: - Letter Point Values

/// Returns the Scrabble point value for a letter
func scrabblePoints(for letter: Character) -> Int {
    switch letter.uppercased().first ?? " " {
    // 1 point
    case "A", "E", "I", "O", "U", "L", "N", "S", "T", "R":
        return 1
    // 2 points
    case "D", "G":
        return 2
    // 3 points
    case "B", "C", "M", "P":
        return 3
    // 4 points
    case "F", "H", "V", "W", "Y":
        return 4
    // 5 points
    case "K":
        return 5
    // 8 points
    case "J", "X":
        return 8
    // 10 points
    case "Q", "Z":
        return 10
    default:
        return 0
    }
}

// MARK: - Score Calculation

/// Represents a letter tile with its bonus multiplier
struct LetterTile: Identifiable {
    let id = UUID()
    let letter: Character
    var multiplier: Int = 1  // 1 = normal, 2 = double letter, 3 = triple letter
    var isBlank: Bool = false  // Blank tiles score 0 points but can represent any letter
    
    var basePoints: Int {
        isBlank ? 0 : scrabblePoints(for: letter)
    }
    
    var points: Int {
        basePoints * multiplier
    }
}

/// Calculate total score for a word with letter and word multipliers
/// - Parameters:
///   - tiles: Array of letter tiles with their multipliers
///   - wordMultiplier: Word bonus (1 = normal, 2 = double word, 3 = triple word)
///   - includesBingo: Whether all 7 tiles were used (adds 50 point bonus)
func calculateWordScore(tiles: [LetterTile], wordMultiplier: Int, includesBingo: Bool = false) -> Int {
    let letterTotal = tiles.reduce(0) { $0 + $1.points }
    let wordScore = letterTotal * wordMultiplier
    return includesBingo ? wordScore + 50 : wordScore
}

// MARK: - Dictionary Type

enum ScrabbleDictionary: String, CaseIterable {
    case us = "US (TWL)"      // Tournament Word List - North America
    case uk = "UK (SOWPODS)"  // Used in UK and internationally
    
    var description: String {
        switch self {
        case .us: return "US/Canada (TWL)"
        case .uk: return "UK/International (SOWPODS)"
        }
    }
}

// MARK: - Word Validation

enum WordValidationStatus {
    case valid       // Confirmed valid word
    case invalid     // Not in dictionary
    case tooShort    // Less than 2 letters
    case hasNumbers  // Contains non-letter characters
    
    var message: String {
        switch self {
        case .valid: return "Valid word ✓"
        case .invalid: return "Not in dictionary"
        case .tooShort: return "Enter a word (2+ letters)"
        case .hasNumbers: return "Letters only"
        }
    }
    
    var isAcceptable: Bool {
        self == .valid
    }
}

/// Word validator using dictionary word lists
class WordValidator {
    
    // Shared instance
    static let shared = WordValidator()
    
    // Current dictionary setting
    var currentDictionary: ScrabbleDictionary = .uk
    
    // Word sets for each dictionary
    private var usWords: Set<String> = []
    private var ukWords: Set<String> = []
    
    // Track if we loaded from files
    private var loadedFromFiles = false
    
    init() {
        loadDictionaries()
    }
    
    private func loadDictionaries() {
        // Try to load from bundled text files first
        if let usURL = Bundle.main.url(forResource: "twl_dictionary", withExtension: "txt"),
           let usContent = try? String(contentsOf: usURL, encoding: .utf8) {
            usWords = Set(usContent.lowercased().components(separatedBy: .newlines).filter { !$0.isEmpty })
            loadedFromFiles = true
            print("Loaded US dictionary: \(usWords.count) words")
        }
        
        if let ukURL = Bundle.main.url(forResource: "sowpods_dictionary", withExtension: "txt"),
           let ukContent = try? String(contentsOf: ukURL, encoding: .utf8) {
            ukWords = Set(ukContent.lowercased().components(separatedBy: .newlines).filter { !$0.isEmpty })
            loadedFromFiles = true
            print("Loaded UK dictionary: \(ukWords.count) words")
        }
        
        // Fall back to built-in word list if files not found
        if usWords.isEmpty || ukWords.isEmpty {
            loadBuiltInDictionary()
        }
    }
    
    private func loadBuiltInDictionary() {
        // Built-in word list as fallback
        // This is a curated list of common valid Scrabble words
        
        let commonWords: Set<String> = [
            // 2-letter words (all valid 2-letter Scrabble words)
            "aa", "ab", "ad", "ae", "ag", "ah", "ai", "al", "am", "an", "ar", "as", "at", "aw", "ax", "ay",
            "ba", "be", "bi", "bo", "by",
            "da", "de", "di", "do",
            "ed", "ef", "eh", "el", "em", "en", "er", "es", "et", "ew", "ex",
            "fa", "fe",
            "gi", "go", "gu",
            "ha", "he", "hi", "hm", "ho",
            "id", "if", "in", "is", "it",
            "ja", "jo",
            "ka", "ki",
            "la", "li", "lo",
            "ma", "me", "mi", "mm", "mo", "mu", "my",
            "na", "ne", "no", "nu",
            "od", "oe", "of", "oh", "oi", "ok", "om", "on", "oo", "op", "or", "os", "ou", "ow", "ox", "oy",
            "pa", "pe", "pi", "po",
            "qi",
            "re",
            "sh", "si", "so",
            "ta", "te", "ti", "to",
            "uh", "um", "un", "up", "ur", "us", "ut",
            "we", "wo",
            "xi", "xu",
            "ya", "ye", "yo",
            "za", "zo",
            
            // 3-letter words (common)
            "ace", "act", "add", "ado", "ads", "aft", "age", "ago", "aid", "aim", "air", "ale", "all", "and", "ant", "any", "ape", "apt", "arc", "are", "ark", "arm", "art", "ash", "ask", "ate", "awe", "awl", "axe", "aye",
            "bad", "bag", "ban", "bar", "bat", "bay", "bed", "bee", "beg", "bet", "bib", "bid", "big", "bin", "bit", "boa", "bob", "bod", "bog", "bop", "bow", "box", "boy", "bra", "bud", "bug", "bum", "bun", "bur", "bus", "but", "buy",
            "cab", "cad", "cam", "can", "cap", "car", "cat", "caw", "cod", "cog", "cop", "cot", "cow", "coy", "cry", "cub", "cud", "cue", "cup", "cur", "cut",
            "dab", "dad", "dam", "day", "den", "dew", "did", "die", "dig", "dim", "din", "dip", "doe", "dog", "don", "dot", "dry", "dub", "dud", "due", "dug", "dun", "duo", "dye",
            "ear", "eat", "eel", "egg", "ego", "elf", "elk", "elm", "emu", "end", "era", "err", "eve", "ewe", "eye",
            "fab", "fad", "fan", "far", "fat", "fax", "fed", "fee", "fen", "few", "fib", "fig", "fin", "fir", "fit", "fix", "fly", "fob", "foe", "fog", "fop", "for", "fox", "fry", "fun", "fur",
            "gab", "gag", "gal", "gap", "gas", "gay", "gel", "gem", "get", "gig", "gin", "gnu", "gob", "god", "got", "gum", "gun", "gut", "guy", "gym",
            "had", "hag", "ham", "has", "hat", "hay", "hem", "hen", "her", "hew", "hex", "hid", "him", "hip", "his", "hit", "hob", "hod", "hoe", "hog", "hop", "hot", "how", "hub", "hue", "hug", "hum", "hut",
            "ice", "icy", "ill", "imp", "ink", "inn", "ion", "ire", "irk", "its", "ivy",
            "jab", "jag", "jam", "jar", "jaw", "jay", "jet", "jib", "jig", "job", "jog", "jot", "joy", "jug", "jut",
            "keg", "ken", "key", "kid", "kin", "kit",
            "lab", "lac", "lad", "lag", "lap", "law", "lax", "lay", "lea", "led", "leg", "let", "lib", "lid", "lie", "lip", "lit", "lob", "log", "lop", "lot", "low", "lug",
            "mad", "man", "map", "mar", "mat", "maw", "may", "men", "met", "mid", "mix", "mob", "mod", "mom", "mop", "mow", "mud", "mug", "mum",
            "nab", "nag", "nap", "nay", "net", "new", "nib", "nil", "nip", "nit", "nob", "nod", "nor", "not", "now", "nub", "nun", "nut",
            "oak", "oar", "oat", "odd", "ode", "off", "oft", "ohm", "oil", "old", "one", "opt", "orb", "ore", "our", "out", "owe", "owl", "own",
            "pac", "pad", "pal", "pan", "pap", "par", "pat", "paw", "pay", "pea", "peg", "pen", "pep", "per", "pet", "pew", "pie", "pig", "pin", "pit", "ply", "pod", "pop", "pot", "pow", "pro", "pry", "pub", "pug", "pun", "pup", "pus", "put",
            "qua",
            "rad", "rag", "ram", "ran", "rap", "rat", "raw", "ray", "red", "ref", "rep", "rev", "rib", "rid", "rig", "rim", "rip", "rob", "rod", "roe", "rot", "row", "rub", "rug", "rum", "run", "rut", "rye",
            "sac", "sad", "sag", "sap", "sat", "saw", "say", "sea", "set", "sew", "she", "shy", "sin", "sip", "sir", "sis", "sit", "six", "ski", "sky", "sly", "sob", "sod", "son", "sop", "sot", "sow", "soy", "spa", "spy", "sty", "sub", "sue", "sum", "sun", "sup",
            "tab", "tad", "tag", "tan", "tap", "tar", "tat", "tax", "tea", "ten", "the", "thy", "tic", "tie", "tin", "tip", "tit", "toe", "tog", "tom", "ton", "too", "top", "tot", "tow", "toy", "try", "tub", "tug", "tun", "tut", "two",
            "ugh", "ump", "uns", "ups", "urn", "use",
            "van", "vat", "vet", "vex", "via", "vie", "vim", "vow",
            "wad", "wag", "war", "was", "wax", "way", "web", "wed", "wee", "wet", "who", "why", "wig", "win", "wit", "woe", "wok", "won", "woo", "wow",
            "yak", "yam", "yap", "yaw", "yea", "yep", "yes", "yet", "yew", "yin", "yip", "you", "yow", "yup",
            "zag", "zap", "zed", "zee", "zen", "zig", "zip", "zit", "zoo",
            
            // 4-letter words (common)
            "able", "ache", "acid", "acne", "acre", "aged", "aide", "ally", "also", "alto", "amid", "ankh", "ante", "aqua", "arch", "area", "aria", "army", "arts", "atom", "aunt", "auto", "avid", "away", "axle",
            "babe", "baby", "back", "bail", "bait", "bake", "bald", "bale", "ball", "balm", "band", "bane", "bang", "bank", "barb", "bare", "bark", "barn", "base", "bash", "bask", "bass", "bath", "bead", "beak", "beam", "bean", "bear", "beat", "beck", "beef", "been", "beer", "bell", "belt", "bend", "bent", "best", "bias", "bike", "bile", "bill", "bind", "bird", "bite", "blow", "blue", "blur", "boar", "boat", "body", "boil", "bold", "bolt", "bomb", "bond", "bone", "book", "boom", "boon", "boot", "bore", "born", "boss", "both", "bout", "bowl", "brag", "bran", "brat", "bred", "brew", "brim", "buck", "buff", "bulb", "bulk", "bull", "bump", "bunk", "burn", "burp", "bury", "bush", "bust", "busy", "buzz",
            "cafe", "cage", "cake", "calf", "call", "calm", "came", "camp", "cane", "cape", "card", "care", "carp", "cart", "case", "cash", "cask", "cast", "cave", "cell", "chad", "char", "chat", "chef", "chew", "chic", "chin", "chip", "chop", "chow", "cite", "city", "clad", "clam", "clan", "clap", "claw", "clay", "clip", "clod", "clog", "club", "clue", "coal", "coat", "cock", "code", "coil", "coin", "coke", "cold", "cole", "colt", "comb", "come", "cone", "cook", "cool", "cope", "copy", "cord", "core", "cork", "corn", "cost", "cosy", "coup", "cove", "cozy", "crab", "cram", "crew", "crib", "crop", "crow", "crud", "cube", "cult", "curb", "curd", "cure", "curl", "cute",
            "daft", "dame", "damp", "dare", "dark", "darn", "dart", "dash", "data", "date", "dawn", "days", "daze", "dead", "deaf", "deal", "dean", "dear", "debt", "deck", "deed", "deem", "deep", "deer", "demo", "dent", "deny", "desk", "dial", "dice", "diet", "dime", "dine", "dire", "dirt", "disc", "dish", "disk", "dive", "dock", "does", "dole", "doll", "dome", "done", "doom", "door", "dope", "dork", "dorm", "dose", "dote", "dour", "dove", "down", "doze", "drab", "drag", "drat", "draw", "drew", "drip", "drop", "drug", "drum", "dual", "dubs", "duck", "duct", "dude", "duel", "duet", "duke", "dull", "dumb", "dump", "dune", "dung", "dunk", "dupe", "dusk", "dust", "duty",
            "each", "earl", "earn", "ease", "east", "easy", "eats", "echo", "edge", "edgy", "edit", "else", "emit", "envy", "epic", "even", "ever", "evil", "exam", "exec", "exit", "expo",
            "face", "fact", "fade", "fail", "fair", "fake", "fall", "fame", "fang", "fare", "farm", "fart", "fast", "fate", "fawn", "fear", "feat", "feed", "feel", "feet", "fell", "felt", "fend", "fern", "fest", "feud", "file", "fill", "film", "find", "fine", "fire", "firm", "fish", "fist", "five", "flag", "flak", "flam", "flan", "flap", "flat", "flaw", "flax", "flay", "flea", "fled", "flee", "flew", "flex", "flip", "flit", "flog", "flop", "flow", "flub", "flue", "flux", "foam", "foil", "fold", "folk", "fond", "font", "food", "fool", "foot", "ford", "fore", "fork", "form", "fort", "foul", "four", "fowl", "foxy", "fray", "free", "fret", "frog", "from", "fuel", "full", "fume", "fund", "funk", "furl", "fury", "fuse", "fuss", "fuzz",
            "gain", "gait", "gale", "gall", "game", "gang", "gape", "garb", "gash", "gasp", "gate", "gave", "gawk", "gaze", "gear", "geek", "gene", "germ", "gets", "gift", "gild", "gilt", "girl", "gist", "give", "glad", "glam", "glee", "glen", "glib", "glob", "glom", "glop", "glow", "glue", "glum", "glut", "gnar", "gnaw", "goad", "goal", "goat", "goes", "gold", "golf", "gone", "gong", "good", "goof", "gore", "gory", "gosh", "goth", "gout", "gown", "grab", "grad", "gram", "gray", "grew", "grey", "grid", "grim", "grin", "grip", "grit", "grow", "grub", "gulf", "gulp", "gunk", "guru", "gush", "gust", "guts", "gyms",
            "hack", "hail", "hair", "hale", "half", "hall", "halt", "hand", "hang", "hank", "hard", "hare", "harm", "harp", "hash", "hasp", "hate", "hath", "haul", "have", "hawk", "haze", "hazy", "head", "heal", "heap", "hear", "heat", "heck", "heed", "heel", "heft", "held", "hell", "helm", "help", "hemp", "hens", "herb", "herd", "here", "hero", "hers", "hewn", "hick", "hide", "high", "hike", "hill", "hilt", "hind", "hint", "hire", "hiss", "hits", "hive", "hoax", "hock", "hogs", "hold", "hole", "holy", "home", "hone", "honk", "hood", "hoof", "hook", "hoop", "hoot", "hope", "hops", "horn", "hose", "host", "hour", "howl", "hubs", "hued", "hues", "huff", "huge", "hugs", "hulk", "hull", "hump", "hums", "hung", "hunk", "hunt", "hurl", "hurt", "hush", "husk", "Hyde", "hymn", "hype",
            "iced", "ices", "icon", "idea", "idle", "idly", "idol", "iffy", "inch", "info", "into", "ions", "iris", "irks", "iron", "isle", "itch", "item", "itty",
            "jack", "jade", "jail", "jams", "jane", "jars", "java", "jaws", "jays", "jazz", "jean", "jeer", "jell", "jerk", "jest", "jets", "jibe", "jiff", "jigs", "jilt", "jinx", "jive", "jobs", "jock", "jogs", "john", "join", "joke", "jolt", "josh", "jots", "jowl", "joys", "judo", "jugs", "jump", "June", "junk", "jury", "just", "juts",
            "kale", "keen", "keep", "kegs", "kelp", "kent", "kept", "keys", "kick", "kids", "kill", "kiln", "kilt", "kind", "king", "kink", "kiss", "kite", "kits", "knee", "knew", "knit", "knob", "knot", "know",
            "labs", "lace", "lack", "lacy", "lads", "lady", "lags", "laid", "lair", "lake", "lame", "lamp", "land", "lane", "laps", "lard", "lark", "lash", "lass", "last", "late", "laud", "lava", "lawn", "laws", "lays", "laze", "lazy", "lead", "leaf", "leak", "lean", "leap", "left", "legs", "lend", "lens", "lent", "less", "lest", "liar", "libs", "lice", "lick", "lids", "lied", "lien", "lies", "life", "lift", "like", "limb", "lime", "limp", "line", "link", "lint", "lion", "lips", "lisp", "list", "live", "load", "loaf", "loam", "loan", "lobe", "lobs", "lock", "lode", "loft", "logo", "logs", "lone", "long", "look", "loom", "loon", "loop", "loot", "lord", "lore", "lose", "loss", "lost", "lots", "loud", "lour", "lout", "love", "lows", "luck", "luge", "lull", "lump", "lung", "lure", "lurk", "lush", "lust", "lynx",
            "mace", "made", "maid", "mail", "maim", "main", "make", "male", "mall", "malt", "mama", "mane", "many", "maps", "mare", "mark", "mars", "mash", "mask", "mass", "mast", "mate", "math", "mats", "maul", "mayo", "maze", "mead", "meal", "mean", "meat", "meek", "meet", "meld", "melt", "memo", "mend", "menu", "meow", "mere", "mesh", "mess", "meth", "mica", "mice", "mild", "mile", "milk", "mill", "mime", "mind", "mine", "mini", "mink", "mint", "minx", "mire", "miss", "mist", "mite", "mitt", "moan", "moat", "mobs", "mock", "mode", "mojo", "mold", "mole", "molt", "monk", "mood", "moon", "moor", "moot", "mops", "more", "morn", "moss", "most", "moth", "move", "much", "muck", "muds", "muff", "mugs", "mule", "mull", "mumm", "mums", "murk", "muse", "mush", "musk", "muss", "must", "mute", "mutt", "myth",
            "nabs", "nags", "nail", "name", "nape", "naps", "navy", "near", "neat", "neck", "need", "neon", "nerd", "nest", "nets", "news", "newt", "next", "nibs", "nice", "nick", "nine", "nips", "node", "nods", "noir", "none", "nook", "noon", "nope", "norm", "nose", "nosy", "note", "noun", "nova", "nubs", "nude", "nuke", "null", "numb", "nuns", "nuts",
            "oafs", "oaks", "oars", "oath", "oats", "obey", "oboe", "odds", "odes", "odor", "offs", "ogre", "ogle", "oils", "oily", "okay", "okra", "omen", "omit", "once", "ones", "only", "onto", "onus", "oohs", "oops", "ooze", "oozy", "opal", "open", "opts", "opus", "oral", "orbs", "orca", "ores", "ouch", "ours", "oust", "outs", "ouzo", "oval", "oven", "over", "owed", "owes", "owls", "owns",
            "pace", "pack", "pact", "pads", "page", "paid", "pail", "pain", "pair", "pale", "palm", "pals", "pane", "pang", "pans", "pant", "papa", "park", "part", "pass", "past", "path", "pats", "pave", "pawn", "paws", "pays", "peak", "peal", "pear", "peas", "peat", "peck", "peek", "peel", "peep", "peer", "pegs", "pelt", "pend", "pens", "pent", "peon", "perk", "perm", "perp", "pert", "peso", "pest", "pets", "pews", "pick", "pier", "pies", "pigs", "pike", "pile", "pill", "pimp", "pine", "ping", "pink", "pins", "pint", "pipe", "pips", "pita", "pits", "pity", "plan", "play", "plea", "pled", "plod", "plop", "plot", "plow", "ploy", "plug", "plum", "plus", "pock", "pods", "poem", "poet", "poke", "poky", "pole", "poll", "polo", "pomp", "pond", "pony", "pooh", "pool", "poop", "poor", "pope", "pops", "pore", "pork", "porn", "port", "pose", "posh", "post", "posy", "pour", "pout", "prep", "prey", "prim", "prism", "prod", "prom", "prop", "pros", "prow", "pubs", "puck", "puff", "pugs", "pull", "pulp", "pump", "puns", "punk", "puns", "puny", "pups", "pure", "purr", "push", "puts", "putt", "pyre",
            "quad", "quay", "quid", "quit", "quiz",
            "race", "rack", "raft", "rage", "rags", "raid", "rail", "rain", "rake", "ramp", "rams", "rang", "rank", "rant", "rape", "raps", "rapt", "rare", "rash", "rasp", "rate", "rats", "rave", "rays", "raze", "razz", "read", "real", "ream", "reap", "rear", "redo", "reds", "reed", "reef", "reek", "reel", "refs", "rein", "rely", "rend", "rent", "repo", "reps", "rest", "revs", "ribs", "rice", "rich", "ride", "rids", "rife", "riff", "rift", "rigs", "rile", "rill", "rims", "rind", "ring", "rink", "riot", "ripe", "rips", "rise", "risk", "rite", "road", "roam", "roar", "robe", "robs", "rock", "rode", "rods", "role", "roll", "romp", "roof", "room", "root", "rope", "ropy", "rose", "rosy", "rots", "roue", "rout", "rove", "rows", "rube", "rubs", "ruby", "ruck", "rude", "rued", "rues", "ruff", "rugs", "ruin", "rule", "rump", "rums", "rune", "rung", "runs", "runt", "ruse", "rush", "rust", "ruts",
            "sack", "safe", "saga", "sage", "sags", "said", "sail", "sake", "sale", "salt", "same", "sand", "sane", "sang", "sank", "saps", "sari", "sash", "sass", "save", "sawn", "saws", "says", "scab", "scam", "scan", "scar", "scat", "seal", "seam", "sear", "seas", "seat", "sect", "seed", "seek", "seem", "seen", "seep", "seer", "sees", "self", "sell", "semi", "send", "sent", "sept", "sets", "sewn", "sews", "sexy", "shag", "sham", "shaw", "shed", "shim", "shin", "ship", "shiv", "shmo", "shod", "shoe", "shoo", "shop", "shot", "show", "shun", "shut", "sick", "side", "sift", "sigh", "sign", "silk", "sill", "silo", "silt", "sine", "sing", "sink", "sips", "sire", "sirs", "site", "sits", "size", "skew", "skid", "skim", "skin", "skip", "skit", "slab", "slag", "slam", "slap", "slat", "slaw", "slay", "sled", "slew", "slid", "slim", "slit", "slob", "sloe", "slog", "slop", "slot", "slow", "slob", "slue", "slug", "slum", "slur", "slut", "smog", "snap", "snag", "snag", "snip", "snit", "snob", "snot", "snow", "snub", "snug", "soak", "soap", "soar", "sobs", "sock", "soda", "sods", "sofa", "soft", "soil", "sold", "sole", "solo", "some", "song", "sons", "soon", "soot", "sops", "sore", "sort", "sots", "soul", "soup", "sour", "sown", "sows", "span", "spar", "spas", "spat", "spay", "spec", "sped", "spew", "spin", "spit", "spot", "spry", "spud", "spun", "spur", "stab", "stag", "star", "stat", "stay", "stem", "step", "stew", "stir", "stop", "stow", "stub", "stud", "stun", "subs", "such", "suck", "suds", "sued", "sues", "suit", "sulk", "sumo", "sump", "sums", "sung", "sunk", "suns", "sure", "surf", "suss", "swab", "swam", "swan", "swap", "swat", "sway", "swim", "swob", "swop", "swum",
            "tabs", "tack", "taco", "tact", "tags", "tail", "take", "tale", "talk", "tall", "tame", "tamp", "tang", "tank", "tans", "tape", "taps", "tare", "tarn", "taro", "tarp", "tars", "tart", "task", "taxi", "teak", "teal", "team", "tear", "teas", "teat", "tech", "teed", "teem", "teen", "tees", "tell", "temp", "tend", "tens", "tent", "term", "tern", "test", "text", "than", "that", "thaw", "them", "then", "thew", "they", "thin", "this", "thou", "thud", "thug", "thus", "tick", "tide", "tidy", "tied", "tier", "ties", "tiff", "tile", "till", "tilt", "time", "tine", "ting", "tins", "tint", "tiny", "tips", "tire", "toad", "tock", "toed", "toes", "toff", "tofu", "toga", "togs", "toil", "told", "toll", "tomb", "tome", "tone", "tong", "tons", "tony", "took", "tool", "toot", "tops", "tore", "torn", "tort", "toss", "tote", "tots", "tour", "tout", "town", "tows", "toys", "tram", "trap", "tray", "tree", "trek", "trim", "trio", "trip", "trod", "trot", "true", "tsar", "tuba", "tube", "tubs", "tuck", "tuft", "tugs", "tulip", "tuna", "tune", "turf", "turn", "tusk", "tutu", "twig", "twin", "twit", "twos", "tyke", "type", "typo",
            "uber", "udder", "ugly", "ulna", "umps", "undo", "unit", "unto", "upon", "urea", "urge", "urns", "used", "user", "uses",
            "vain", "vale", "vamp", "vane", "vans", "vary", "vase", "vast", "vats", "veal", "veer", "veil", "vein", "vend", "vent", "verb", "very", "vest", "veto", "vets", "vial", "vibe", "vice", "vied", "vies", "view", "vile", "vine", "visa", "vise", "vita", "viva", "void", "vole", "volt", "vote", "vows",
            "wade", "wads", "waft", "wage", "wags", "waif", "wail", "wait", "wake", "walk", "wall", "wand", "wane", "want", "ward", "ware", "warm", "warn", "warp", "wars", "wart", "wary", "wash", "wasp", "wave", "wavy", "waxy", "ways", "weak", "wean", "wear", "webs", "weds", "weed", "week", "weep", "weld", "well", "welt", "went", "wept", "were", "west", "wets", "wham", "what", "when", "whet", "whew", "whey", "whim", "whip", "whir", "whit", "whiz", "whom", "wick", "wide", "wife", "wigs", "wild", "will", "wilt", "wimp", "wind", "wine", "wing", "wink", "wins", "wipe", "wire", "wiry", "wise", "wish", "wisp", "with", "wits", "wive", "woes", "woke", "woks", "wolf", "womb", "wonk", "wont", "wood", "woof", "wool", "woos", "word", "wore", "work", "worm", "worn", "wort", "wove", "wows", "wrap", "wren", "writ",
            "xerox",
            "yacht", "yack", "yaks", "yams", "yang", "yank", "yaps", "yard", "yarn", "yawl", "yawn", "yawp", "yaws", "yeah", "year", "yeas", "yell", "yelp", "yens", "yeps", "yerk", "yess", "yeti", "yews", "yids", "yikes", "ying", "yipe", "yips", "yoke", "yolk", "yore", "your", "yowl", "yows", "yuan", "yuck", "yuks", "yule", "yummy", "yups", "yurt",
            "zags", "zany", "zaps", "zeal", "zebu", "zeds", "zees", "zens", "zephyr", "zero", "zest", "zigs", "zinc", "zine", "zing", "zips", "ziti", "zits", "zone", "zonk", "zoom", "zoos",
            
            // 5+ letter words (common)
            "about", "above", "abuse", "acorn", "acted", "actor", "acute", "added", "admit", "adopt", "adult", "after", "again", "agent", "agree", "ahead", "aimed", "alarm", "album", "alert", "alien", "align", "alike", "alive", "alley", "allow", "alloy", "alone", "along", "alpha", "alter", "amaze", "amber", "amend", "ample", "angel", "anger", "angle", "angry", "ankle", "annoy", "antic", "anvil", "apart", "apple", "apply", "apron", "arena", "argue", "arise", "armor", "aroma", "arose", "array", "arrow", "arson", "ascot", "aside", "asset", "atlas", "attic", "audio", "audit", "avoid", "await", "awake", "award", "aware", "awful",
            "bacon", "badge", "badly", "bagel", "baker", "barge", "basic", "basin", "basis", "batch", "beach", "beard", "beast", "began", "begin", "begun", "being", "belly", "below", "bench", "berry", "birth", "black", "blade", "blame", "bland", "blank", "blast", "blaze", "bleak", "bleed", "blend", "bless", "blind", "blink", "bliss", "block", "bloke", "blond", "blood", "bloom", "blown", "blues", "bluff", "blunt", "blurb", "blurt", "blush", "board", "boast", "bones", "bonus", "boost", "booth", "booze", "bored", "botch", "bough", "bound", "brain", "brake", "brand", "brass", "brave", "bravo", "bread", "break", "breed", "brick", "bride", "brief", "bring", "brink", "brisk", "broad", "broil", "broke", "brood", "brook", "broom", "broth", "brown", "brunt", "brush", "brute", "build", "built", "bunch", "burns", "burnt", "burst", "buyer",
            "cabal", "cabin", "cable", "cache", "cadet", "caged", "cajun", "camel", "cameo", "canal", "candy", "canoe", "caper", "carat", "cards", "cargo", "carol", "carry", "carve", "catch", "cater", "cause", "cease", "chain", "chair", "chalk", "champ", "chant", "chaos", "charm", "chart", "chase", "cheap", "cheat", "check", "cheek", "cheer", "chess", "chest", "chick", "chief", "child", "chill", "chimp", "china", "chirp", "chive", "chomp", "chord", "chore", "chose", "chunk", "churn", "cider", "cigar", "cinch", "circa", "civic", "civil", "claim", "clamp", "clang", "clank", "clash", "clasp", "class", "clean", "clear", "clerk", "click", "cliff", "climb", "cling", "cloak", "clock", "clone", "close", "cloth", "cloud", "clout", "clown", "coach", "coast", "cocoa", "colon", "color", "comet", "comic", "comma", "conch", "coral", "couch", "cough", "could", "count", "coupe", "court", "cover", "covet", "crack", "craft", "cramp", "crane", "crank", "crash", "crate", "crave", "crawl", "craze", "crazy", "creak", "cream", "creed", "creek", "creep", "creme", "crepe", "crest", "crick", "cried", "crime", "crimp", "crisp", "croak", "crock", "crook", "cross", "crowd", "crown", "crude", "cruel", "crush", "crust", "crypt", "cubic", "cumin", "curse", "curve", "cycle",
            "daddy", "daily", "dairy", "daisy", "dance", "dated", "dealt", "death", "debit", "debug", "debut", "decal", "decay", "decor", "decoy", "decry", "deity", "delay", "delta", "delve", "demon", "demur", "denim", "dense", "depot", "depth", "derby", "deter", "detox", "devil", "diary", "dicey", "digit", "diner", "dingy", "dirty", "disco", "ditch", "ditto", "dizzy", "dodge", "doing", "dolly", "donor", "donut", "doubt", "dough", "dowel", "dozen", "draft", "drain", "drake", "drama", "drank", "drape", "drawl", "drawn", "dread", "dream", "dress", "dried", "drift", "drill", "drink", "drive", "droit", "droll", "drone", "drool", "droop", "dross", "drove", "drown", "drugs", "drunk", "dryer", "dryly", "ducal", "dully", "dummy", "dumpy", "dune", "dunce", "dwell", "dwelt",
            "eager", "eagle", "early", "earth", "easel", "eaten", "eater", "eaves", "ebony", "edged", "edict", "eerie", "eight", "eject", "elate", "elbow", "elder", "elect", "elite", "elope", "elude", "elves", "email", "embed", "ember", "emcee", "empty", "enact", "ended", "endow", "enemy", "enjoy", "ennui", "enter", "entry", "envoy", "epoch", "equal", "equip", "erase", "erect", "erode", "error", "erupt", "essay", "ether", "ethic", "evade", "event", "every", "evict", "evoke", "exact", "exalt", "excel", "exert", "exile", "exist", "expat", "expel", "extol", "extra", "exude", "exult",
            "fable", "facet", "faddy", "faint", "fairy", "faith", "false", "famed", "fancy", "fanny", "farce", "fatal", "fatty", "fault", "fauna", "favor", "feast", "feign", "feint", "fella", "felon", "femur", "fence", "feral", "ferry", "fetal", "fetch", "fetid", "fetus", "fever", "fewer", "fiber", "fibre", "field", "fiend", "fiery", "fifth", "fifty", "fight", "filch", "filet", "filly", "filmy", "filth", "final", "finch", "finer", "first", "fishy", "fixer", "fizzy", "fjord", "flack", "flair", "flake", "flaky", "flame", "flank", "flare", "flash", "flask", "flatly", "fleck", "flesh", "flick", "flier", "flies", "fling", "flint", "flirt", "float", "flock", "flood", "floor", "floss", "flour", "flout", "flown", "fluff", "fluid", "fluke", "flung", "flunk", "flush", "flute", "focal", "focus", "foggy", "folio", "folly", "fonts", "foray", "force", "forge", "forgo", "forms", "forte", "forth", "forty", "forum", "fossil", "foster", "found", "foyer", "frail", "frame", "frank", "fraud", "freak", "freed", "fresh", "friar", "fried", "frill", "frisk", "fritz", "frizz", "frock", "frolic", "front", "frost", "froth", "frown", "froze", "fruit", "fudge", "fuels", "fugue", "fully", "fumed", "funds", "fungi", "funky", "funny", "furry", "fussy", "fusty", "futile", "fuzzy",
            "gaffe", "gaily", "gamma", "gamut", "gassy", "gauge", "gaunt", "gauze", "gauzy", "gavel", "gawky", "gazer", "gecko", "geeky", "geese", "genie", "genre", "ghost", "giant", "giddy", "gifts", "girth", "given", "giver", "gizmo", "glade", "gland", "glare", "glass", "glaze", "gleam", "glean", "glide", "glint", "glitz", "gloat", "globe", "gloom", "glory", "gloss", "glove", "glued", "glyph", "gnarly", "gnash", "gnome", "godly", "gofer", "going", "golly", "gonna", "goods", "gooey", "goofy", "goose", "gorge", "gotta", "gouge", "gourd", "grace", "grade", "graft", "grail", "grain", "grand", "grant", "grape", "graph", "grasp", "grass", "grate", "grave", "gravy", "graze", "great", "greed", "Greek", "green", "greet", "grief", "grill", "grime", "grimy", "grind", "gripe", "grits", "groan", "groom", "grope", "gross", "group", "grout", "grove", "growl", "grown", "gruel", "gruff", "grump", "grunt", "guard", "guava", "guess", "guest", "guide", "guild", "guilt", "guise", "gulch", "gummy", "gumpy", "gunky", "guppy", "gusto", "gusty", "gutsy",
            "habit", "haiku", "hairs", "hairy", "halve", "handy", "happy", "hardy", "harem", "harpy", "harsh", "haste", "hasty", "hatch", "haunt", "haven", "havoc", "hazel", "heads", "heady", "heard", "heart", "heath", "heave", "heavy", "hedge", "heels", "hefty", "heist", "helix", "hello", "hence", "heron", "hippo", "hitch", "hoard", "hobby", "hoist", "holly", "homer", "honey", "honor", "hooky", "hoped", "horde", "horns", "horny", "horse", "hotel", "hotly", "hound", "house", "hover", "howdy", "hubby", "human", "humid", "humor", "humps", "humus", "hunch", "hunks", "hunky", "hurry", "husky", "hussy", "hutch", "hydra", "hyena", "hymen", "hyper",
            "icily", "icing", "ideal", "idiom", "idiot", "igloo", "image", "imbue", "impel", "imply", "inbox", "incur", "index", "inept", "inert", "infer", "ingot", "inlay", "inlet", "inner", "input", "inter", "intro", "ionic", "irate", "Irish", "irony", "issue", "itchy", "ivory",
            "jacks", "jazzy", "jeans", "jelly", "jerky", "Jesus", "jewel", "jiffy", "jinks", "joint", "joker", "jolly", "joust", "judge", "juice", "juicy", "jumbo", "jumpy", "junco", "junky",
            "karma", "kayak", "kebab", "keyed", "khaki", "kicks", "kinky", "kiosk", "kitty", "knack", "knead", "kneel", "knelt", "knife", "knock", "knoll", "known",
            "label", "labor", "laced", "laden", "ladle", "lager", "lance", "lanky", "lapel", "lapse", "large", "larva", "laser", "lasso", "latch", "later", "latex", "lathe", "latte", "laugh", "layer", "leach", "leafy", "leaky", "leant", "leapt", "learn", "lease", "leash", "least", "leave", "ledge", "leech", "leery", "lefty", "legal", "lemon", "lemur", "level", "lever", "libel", "light", "liked", "liken", "lilac", "limbo", "limit", "lined", "linen", "liner", "lingo", "links", "lions", "lipid", "lists", "liter", "lithe", "lived", "lively", "liver", "llama", "loads", "loamy", "loath", "lobby", "local", "locus", "lodge", "lofty", "logic", "login", "loins", "loner", "looks", "loony", "loose", "loser", "lotto", "lotus", "louse", "lousy", "lover", "lower", "lowly", "loyal", "lucid", "lucky", "lumen", "lumpy", "lunar", "lunch", "lunge", "lusty", "lying", "lymph", "lynch", "lyric",
            "macaw", "macho", "macro", "madam", "madly", "mafia", "magic", "magma", "maize", "major", "maker", "mambo", "mamma", "mammy", "mange", "mango", "mangy", "mania", "manic", "manly", "manor", "maple", "march", "marge", "marry", "marsh", "mason", "match", "mater", "mauve", "maxim", "maybe", "mayor", "mealy", "means", "meant", "meaty", "medal", "media", "medic", "melee", "melon", "mercy", "merge", "merit", "merry", "messy", "metal", "meter", "metro", "micro", "midst", "might", "milky", "mimic", "mince", "miner", "minor", "minus", "mirth", "miser", "missy", "misty", "miter", "mitre", "mixed", "mixer", "mocha", "model", "modem", "moist", "molar", "moldy", "money", "month", "mooch", "moody", "moose", "moral", "moron", "morph", "mossy", "motel", "mothy", "motif", "motor", "motto", "mound", "mount", "mourn", "mouse", "mousy", "mouth", "moved", "mover", "movie", "mucus", "muddy", "mufti", "mulch", "mummy", "munch", "mural", "murky", "mushy", "music", "musky", "musty", "myrrh",
            "nacho", "naive", "nanny", "nasal", "nasty", "natal", "naval", "navel", "needy", "neigh", "nerdy", "nerve", "nervy", "never", "newer", "newly", "nicer", "niche", "niece", "nifty", "night", "ninja", "ninth", "nippy", "nitty", "noble", "nobly", "noise", "noisy", "nomad", "noose", "north", "notch", "noted", "notes", "novel", "nudge", "nurse", "nutty", "nylon", "nymph",
            "oaken", "oasis", "occur", "ocean", "octet", "ocular", "oddly", "offal", "offer", "often", "oiled", "oiler", "olden", "older", "olive", "ombre", "omega", "onion", "onset", "opera", "opium", "optic", "orbit", "order", "organ", "other", "otter", "ought", "ounce", "outdo", "outer", "outgo", "ovary", "overt", "owing", "owner", "oxide", "ozone",
            "paddy", "pagan", "paint", "pairs", "panda", "panel", "panic", "pansy", "panty", "papal", "paper", "parch", "parks", "parry", "parse", "party", "pasta", "paste", "pasty", "patch", "patio", "patsy", "patty", "pause", "payee", "payer", "peace", "peach", "pearl", "pecan", "pedal", "penal", "pence", "penny", "perch", "peril", "perky", "pesky", "pesto", "petal", "petty", "phase", "phone", "phony", "photo", "piano", "picky", "piece", "piety", "piggy", "pilot", "pinch", "piper", "pipit", "pique", "pitch", "pithy", "piton", "pivot", "pixel", "pizza", "place", "plaid", "plain", "plane", "plank", "plant", "plate", "plaza", "plead", "pleat", "pledge", "plier", "plod", "plop", "plop", "pluck", "plumb", "plume", "plump", "plunk", "plush", "poach", "point", "poise", "poker", "polar", "polka", "polyp", "pooch", "poppy", "porch", "porky", "poser", "posit", "posse", "pouch", "pound", "pouty", "power", "prank", "prawn", "preen", "press", "price", "prick", "pride", "pried", "prime", "primp", "prince", "print", "prior", "prism", "privy", "prize", "probe", "promo", "prone", "prong", "proof", "prose", "proud", "prove", "prowl", "proxy", "prude", "prune", "psalm", "pubic", "pudgy", "pulse", "punch", "punks", "pupil", "puppy", "puree", "purge", "purse", "pushy", "putty", "pygmy",
            "quack", "quaff", "quail", "quake", "qualm", "quart", "quasi", "queen", "queer", "query", "quest", "queue", "quick", "quiet", "quilt", "quirk", "quota", "quote",
            "rabbi", "rabid", "racer", "radar", "radii", "radio", "radon", "rainy", "raise", "rajah", "rally", "ralph", "ramen", "ranch", "randy", "range", "rapid", "rarer", "raspy", "ratio", "ratty", "raven", "rayon", "razor", "reach", "react", "ready", "realm", "reams", "rebel", "rebut", "recap", "recur", "refer", "rehab", "reign", "relax", "relay", "relic", "remit", "remix", "repay", "repel", "reply", "rerun", "reset", "resin", "retch", "retro", "retry", "reuse", "revel", "revue", "rhino", "rhyme", "rider", "ridge", "rifle", "right", "rigid", "rigor", "rinse", "ripen", "risen", "riser", "risky", "rival", "river", "rivet", "roach", "roast", "robin", "robot", "rocky", "rodeo", "rogue", "roomy", "roost", "rough", "round", "route", "rover", "rowdy", "royal", "rugby", "ruin", "ruler", "rumba", "rumor", "rupee", "rural", "rusty",
            "sadly", "safer", "saint", "salad", "salon", "salsa", "salty", "salve", "salvo", "sandy", "saner", "sapid", "sappy", "sassy", "Satan", "satin", "satyr", "sauce", "saucy", "sauna", "saute", "savor", "savoy", "savvy", "scald", "scale", "scalp", "scaly", "scamp", "scant", "scare", "scarf", "scary", "scene", "scent", "scoff", "scold", "scone", "scoop", "scoot", "scope", "score", "scorn", "scout", "scowl", "scram", "scrap", "scree", "screw", "scrub", "seams", "sedan", "seedy", "segue", "seize", "sense", "sepia", "serif", "serum", "serve", "setup", "seven", "sever", "sewer", "shade", "shady", "shaft", "shake", "shaky", "shall", "shame", "shank", "shape", "shard", "share", "shark", "sharp", "shave", "shawl", "sheaf", "shear", "sheen", "sheep", "sheer", "sheet", "shelf", "shell", "shift", "shine", "shiny", "shire", "shirk", "shirt", "shock", "shore", "shorn", "short", "shout", "shove", "shown", "showy", "shred", "shrew", "shrub", "shrug", "shuck", "shunt", "shush", "siege", "sight", "sigma", "silky", "silly", "since", "sinew", "singe", "siren", "sissy", "sixth", "sixty", "sized", "skate", "skeet", "sketchy", "skied", "skier", "skill", "skimp", "skirt", "skulk", "skull", "skunk", "slack", "slain", "slang", "slant", "slash", "slate", "slave", "sleek", "sleep", "sleet", "slept", "slice", "slide", "slime", "slimy", "sling", "slink", "slope", "slosh", "sloth", "slump", "slung", "slunk", "slurp", "slush", "slyly", "smack", "small", "smart", "smash", "smear", "smell", "smelt", "smile", "smirk", "smite", "smith", "smock", "smoke", "smoky", "snack", "snafu", "snail", "snake", "snaky", "snare", "snarl", "sneak", "sneer", "snide", "sniff", "snipe", "snoop", "snore", "snort", "snout", "snowy", "snuck", "snuff", "soapy", "sober", "soggy", "solar", "solid", "solve", "sonar", "sonic", "sorry", "sound", "south", "space", "spade", "spank", "spare", "spark", "spasm", "spawn", "speak", "spear", "speck", "speed", "spell", "spend", "spent", "spice", "spicy", "spied", "spiel", "spike", "spiky", "spill", "spine", "spiny", "spire", "spite", "splat", "split", "spoil", "spoke", "spoof", "spook", "spool", "spoon", "spore", "sport", "spout", "spray", "spree", "sprig", "spunk", "spurn", "spurt", "squad", "squat", "squaw", "squib", "stack", "staff", "stage", "staid", "stain", "stair", "stake", "stale", "stalk", "stall", "stamp", "stand", "stank", "staph", "stare", "stark", "stars", "start", "stash", "state", "stave", "stays", "steak", "steal", "steam", "steed", "steel", "steep", "steer", "stein", "stern", "stick", "stiff", "still", "stilt", "sting", "stink", "stint", "stock", "stoic", "stoke", "stole", "stomp", "stone", "stony", "stood", "stool", "stoop", "store", "stork", "storm", "story", "stout", "stove", "strap", "straw", "stray", "strep", "strew", "strip", "strut", "stuck", "study", "stuff", "stump", "stung", "stunk", "stunt", "style", "suave", "sugar", "suite", "sulky", "sunny", "super", "surge", "surly", "sushi", "swamp", "swank", "swarm", "swash", "swath", "swear", "sweat", "sweep", "sweet", "swell", "swept", "swift", "swill", "swine", "swing", "swipe", "swirl", "swish", "swiss", "swoon", "swoop", "sword", "swore", "sworn", "swung", "synod", "syrup",
            "tabby", "table", "taboo", "tacit", "tacky", "taffy", "taint", "taken", "taker", "tally", "talon", "tango", "tangy", "taper", "tapir", "tardy", "taste", "tasty", "tatty", "taunt", "tawny", "teach", "teary", "tease", "teddy", "teeth", "tempo", "tenet", "tenor", "tense", "tenth", "tepid", "terms", "terra", "terse", "test", "thank", "theft", "their", "theme", "there", "these", "thick", "thief", "thigh", "thing", "think", "third", "thong", "thorn", "those", "three", "threw", "throb", "throw", "thrum", "thumb", "thump", "tiara", "tibia", "tidal", "tiger", "tight", "tilde", "timer", "timid", "tipsy", "titan", "title", "toast", "today", "toddy", "token", "tonal", "tonic", "tooth", "topaz", "topic", "torch", "torso", "total", "totem", "touch", "tough", "towel", "tower", "toxic", "toxin", "trace", "track", "tract", "trade", "trail", "train", "trait", "tramp", "trash", "trawl", "tread", "treat", "trend", "triad", "trial", "tribe", "trick", "tried", "trill", "tripe", "trite", "troll", "tromp", "troop", "trout", "truce", "truck", "truly", "trump", "trunk", "truss", "trust", "truth", "tryst", "tubal", "tuber", "tulip", "tummy", "tumor", "tuner", "tunic", "turbo", "tutor", "twain", "twang", "tweak", "tweed", "tweet", "twice", "twine", "twirl", "twist", "tying", "tyrant",
            "udder", "ulcer", "ultra", "umbra", "uncle", "uncut", "under", "undid", "undue", "unfed", "unfit", "unify", "union", "unite", "unity", "unlit", "unmet", "until", "unwed", "unzip", "upper", "upset", "urban", "urine", "usage", "usher", "using", "usual", "usurp", "utile", "utter",
            "vague", "valet", "valid", "valor", "value", "valve", "vapid", "vapor", "vault", "vaunt", "vegas", "veins", "veldt", "venom", "venue", "verge", "verse", "verso", "verve", "vicar", "video", "vigil", "vigor", "villa", "vinyl", "viola", "viper", "viral", "virus", "visor", "vista", "vital", "vivid", "vixen", "vocal", "vodka", "vogue", "voice", "voila", "vomit", "voter", "vouch", "vowel", "vying",
            "wacky", "wafer", "wager", "wagon", "waist", "waltz", "warty", "waste", "watch", "water", "waver", "waxen", "weary", "weave", "wedge", "weedy", "weigh", "weird", "welsh", "wench", "whale", "wharf", "wheat", "wheel", "whelp", "where", "which", "whiff", "while", "whine", "whiny", "whirl", "whisk", "white", "whole", "whoop", "whose", "widen", "wider", "widow", "width", "wield", "wight", "willy", "wimpy", "wince", "winch", "windy", "wiper", "witch", "witty", "woken", "woman", "women", "woods", "woozy", "wordy", "world", "worry", "worse", "worst", "worth", "would", "wound", "woven", "wrack", "wrath", "wreak", "wreck", "wrest", "wring", "wrist", "write", "wrong", "wrote", "wrung", "wryly",
            "xerox",
            "yacht", "yearn", "yeast", "yield", "young", "youth", "yucca",
            "zebra", "zesty", "zilch", "zingy", "zippy", "zonal", "zones"
        ]
        
        // US dictionary - American spellings only
        usWords = commonWords
        
        // UK dictionary - includes British spellings
        // SOWPODS contains all US words PLUS British spellings
        let britishSpellings: Set<String> = [
            // -our spellings (UK) vs -or (US)
            "colour", "colours", "coloured", "colouring",
            "favour", "favours", "favoured", "favouring", "favourite", "favourites",
            "honour", "honours", "honoured", "honouring", "honourable",
            "labour", "labours", "laboured", "labouring", "labourer",
            "neighbour", "neighbours", "neighbourhood",
            "behaviour", "behaviours",
            "flavour", "flavours", "flavoured", "flavouring",
            "humour", "humours", "humoured", "humouring",
            "rumour", "rumours", "rumoured",
            "vapour", "vapours",
            "vigour", "rigour", "rancour", "candour", "clamour", "glamour",
            "armour", "armoured", "armoury",
            "harbour", "harbours", "harboured",
            "savour", "savours", "savoured", "savoury",
            "odour", "odours",
            
            // -ise spellings (UK) vs -ize (US)
            "realise", "realised", "realising",
            "organise", "organised", "organising",
            "recognise", "recognised", "recognising",
            "apologise", "apologised", "apologising",
            "specialise", "specialised", "specialising",
            "criticise", "criticised", "criticising",
            "emphasise", "emphasised", "emphasising",
            "memorise", "memorised", "memorising",
            "nationalise", "nationalised",
            "privatise", "privatised",
            "summarise", "summarised",
            "symbolise", "symbolised",
            "visualise", "visualised",
            
            // -re spellings (UK) vs -er (US)
            "centre", "centres", "centred",
            "theatre", "theatres",
            "metre", "metres",
            "litre", "litres",
            "fibre", "fibres",
            "calibre",
            "sombre",
            "lustre",
            "spectre",
            "sabre", "sabres",
            "meagre",
            
            // -ogue spellings (UK) vs -og (US)
            "catalogue", "catalogues", "catalogued",
            "dialogue", "dialogues",
            "analogue", "analogues",
            "prologue", "prologues",
            "epilogue", "epilogues",
            
            // Double L in UK
            "travelling", "travelled", "traveller", "travellers",
            "cancelling", "cancelled",
            "labelling", "labelled",
            "levelling", "levelled",
            "modelling", "modelled",
            "counselling", "counselled", "counsellor",
            "marvelling", "marvelled", "marvellous",
            "jewellery",
            "woollen",
            "skilful",
            "wilful",
            "fulfil",
            
            // Other UK spellings
            "defence", "defences",
            "offence", "offences",
            "licence", "licences",
            "pretence",
            "practise", "practised", "practising",
            "cheque", "cheques",
            "grey",
            "tyre", "tyres",
            "plough", "ploughs", "ploughed",
            "draught", "draughts", "draughty",
            "gaol", "gaoled",
            "kerb", "kerbs",
            "aluminium",
            "aeroplane", "aeroplanes",
            "cosy", "cosier", "cosiest",
            "pyjamas",
            "moustache", "moustaches",
            "storey", "storeys",
            "furore",
            "annexe",
            "programme", "programmes"
        ]
        
        // UK dictionary = common words + British spellings
        ukWords = commonWords.union(britishSpellings)
    }
    
    /// Check if a word is valid in the current dictionary
    func isValid(_ word: String) -> Bool {
        let cleaned = word.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch currentDictionary {
        case .us:
            return usWords.contains(cleaned)
        case .uk:
            return ukWords.contains(cleaned)
        }
    }
    
    /// Returns validation status for a word
    func validationStatus(_ word: String) -> WordValidationStatus {
        let cleaned = word.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Check for empty or too short
        guard cleaned.count >= 2 else { return .tooShort }
        
        // Check for non-letters
        guard cleaned.allSatisfy({ $0.isLetter }) else { return .hasNumbers }
        
        // Check dictionary
        if isValid(cleaned) {
            return .valid
        } else {
            return .invalid
        }
    }
    
    // MARK: - Static convenience methods (for backward compatibility)
    
    static func validationStatus(_ word: String) -> WordValidationStatus {
        return shared.validationStatus(word)
    }
    
    static func isValid(_ word: String) -> Bool {
        return shared.isValid(word)
    }
}