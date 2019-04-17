package generation {
    import graph.*;

    public class Names {
        private static var _instance:Names;
        private var geo:Geography;
        private var civ:Civilization;

        /**
         * Biomes
         */

        [Embed(source="../assets/names/biomes/tundra.json", mimeType="application/octet-stream")]
        private static const tundra_json:Class;

        [Embed(source="../assets/names/biomes/borealForest.json", mimeType="application/octet-stream")]
        private static const borealForest_json:Class;

        [Embed(source="../assets/names/biomes/grassland.json", mimeType="application/octet-stream")]
        private static const grassland_json:Class;

        [Embed(source="../assets/names/biomes/temperateForest.json", mimeType="application/octet-stream")]
        private static const temperateForest_json:Class;

        [Embed(source="../assets/names/biomes/savanna.json", mimeType="application/octet-stream")]
        private static const savanna_json:Class;

        [Embed(source="../assets/names/biomes/rainForest.json", mimeType="application/octet-stream")]
        private static const rainForest_json:Class;

        [Embed(source="../assets/names/biomes/mountain.json", mimeType="application/octet-stream")]
        private static const mountain_json:Class;

        [Embed(source="../assets/names/biomes/desert.json", mimeType="application/octet-stream")]
        private static const desert_json:Class;

        [Embed(source="../assets/names/biomes/saltWater.json", mimeType="application/octet-stream")]
        private static const saltWater_json:Class;

        [Embed(source="../assets/names/biomes/freshWater.json", mimeType="application/octet-stream")]
        private static const freshWater_json:Class;

        public var tundra:Object;
        public var borealForest:Object;
        public var grassland:Object;
        public var temperateForest:Object;
        public var savanna:Object;
        public var rainForest:Object;
        public var mountain:Object;
        public var desert:Object;
        public var freshWater:Object;
        public var saltWater:Object;

        /**
         * Features
         */

        [Embed(source="../assets/names/places/prefixesByContext.json", mimeType="application/octet-stream")]
        private static const prefixesByContext_json:Class;

        [Embed(source="../assets/names/places/suffixesByContext.json", mimeType="application/octet-stream")]
        private static const suffixesByContext_json:Class;

        [Embed(source="../assets/names/places/suffixesByNamingGroup.json", mimeType="application/octet-stream")]
        private static const suffixesByNamingGroup_json:Class;

        public var prefixesByContext:Object;
        public var suffixesByContext:Object;
        public var suffixesByNamingGroup:Object;

        private var existingNames:Array = [];

        public static function getInstance():Names {
            if (!_instance)
                new Names();
            return _instance;
        }

        public function Names() {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;

            geo = Geography.getInstance();
            civ = Civilization.getInstance();

            // Biomes
            tundra = JSON.parse(new tundra_json());
            borealForest = JSON.parse(new borealForest_json());
            grassland = JSON.parse(new grassland_json());
            temperateForest = JSON.parse(new temperateForest_json());
            savanna = JSON.parse(new savanna_json());
            rainForest = JSON.parse(new rainForest_json());
            mountain = JSON.parse(new mountain_json());
            desert = JSON.parse(new desert_json());
            freshWater = JSON.parse(new freshWater_json());
            saltWater = JSON.parse(new saltWater_json());

            // Places
            prefixesByContext = JSON.parse(new prefixesByContext_json());
            suffixesByContext = JSON.parse(new suffixesByContext_json());
            suffixesByNamingGroup = JSON.parse(new suffixesByNamingGroup_json());
        }

        public function analyzeLand(cells:Vector.<Cell>):Object {
            var analysis:Object = {};

            // Size
            analysis.size = cells.length;

            if (cells.length < 3) {
                // Tiny island
                analysis.tinyIsland = true;
            } else if (cells.length < 100) {
                // Small island
                analysis.smallIsland = true;
            } else if (cells.length < 400) {
                // Large island
                analysis.largeIsland = true;
            } else {
                // Continent
                analysis.continent = true;
            }

            return analysis;
        }

        public function analyzeRegionProperties(cells:Vector.<Cell>):Object {
            var analysis:Object = {};

            // Array of biomes and their percent of cells
            var regionalBiomesObject:Object = {};
            for each (var cell:Cell in cells) {
                if (regionalBiomesObject[cell.biomeType])
                    regionalBiomesObject[cell.biomeType].count++;
                else if (cell.biomeType)
                    regionalBiomesObject[cell.biomeType] = {type: cell.biomeType, count: 1};
            }
            var regionalBiomes:Array = [];
            for each (var regionalBiome:Object in regionalBiomesObject) {
                if (regionalBiome.count > 0) {
                    regionalBiomes.push(regionalBiome);
                    regionalBiome.percent = regionalBiome.count / cells.length;
                }
            }
            regionalBiomes.sortOn("count");
            if (regionalBiomes[0].percent > .4)
                analysis[regionalBiomes[0].type] = true;

            // Percent of river cells
            // Percent of lake cells
            // Percent of coastal cells
            // Average elevation
            var riverCount:int = 0;
            var lakeCount:int = 0;
            var coastalCount:int = 0;
            var averageElevation:Number = 0;
            var averageTemperature:Number = 0;
            for each (cell in cells) {
                if (cell.hasFeatureType(Geography.RIVER))
                    riverCount++;

                if (cell.hasFeatureType(Geography.LAKE))
                    lakeCount++;

                if (cell.coastal)
                    coastalCount++;

                averageElevation += cell.elevation;
                averageTemperature += cell.temperature;
            }

            if (riverCount > 2)
                analysis.highRiverRating = true;

            if (lakeCount > 2)
                analysis.highLakeRating = true;

            if (coastalCount / cells.length > .4)
                analysis.highCoastalRating = true;

            averageElevation = averageElevation / cells.length;
            averageTemperature = averageTemperature / cells.length;

            if (averageElevation < .4)
                analysis.lowElevation = true;
            else if (averageElevation > .6)
                analysis.highElevation = true;

            if (averageTemperature < .3)
                analysis.lowTemperature = true;
            else if (averageTemperature > .5)
                analysis.highTemperature = true;

            // Analyze land (regions cannot span more than one land so don't worry about it)
            var lands:Object = cells[0].getFeaturesByType(Geography.LAND);
            for each (var land:Object in lands)
                break;
            if (land.cells.length < 3) {
                // Tiny island
                analysis.tinyIslandOrSmallIsland = true;
            } else if (land.cells.length < 100) {
                // Small island
                analysis.tinyIslandOrSmallIsland = true;
            } else if (land.cells.length < 400) {
                // Large island
                analysis.largeIslandOrContinent = true;
            } else {
                // Continent
                analysis.largeIslandOrContinent = true;
            }

            return analysis;
        }

        private function analyzeRegionContext(region:Object):Object {
            var analysis:Object = region.analysis;

            // Get references to neighboring regions
            var neighborRegions:Object = {};
            for each (var cell:Cell in region.cells) {
                for each(var neighbor:Cell in cell.neighbors) {
                    if (neighbor.region != cell.region) {
                        // Cell is a border cell
                        // Only add neighbor's region if it's not null (ocean)
                        if (neighbor.region)
                            neighborRegions[neighbor.region] = {region: civ.regions[neighbor.region]};
                    }
                }
            }

            var keys:Array = [];
            for (var key:String in analysis)
                keys.push(key);

            for each (var neighborRegion:Object in neighborRegions) {
                var neighborKeys:Array = [];
                for (key in neighborRegion.region.analysis)
                    neighborKeys.push(key);
                // Compare the two key sets
                var shared:Array = Util.sharedPropertiesBetweenArrays(keys, neighborKeys);
                neighborRegion.compare = shared.length / keys.length;

                // Add the degrees between the two regions
                neighborRegion.degrees = Util.getAngleBetweenTwoPoints(region.centroid, neighborRegion.region.centroid);

                // Compass direction from angle
                neighborRegion.compassDirection = Util.getCompassDirectionFromDegrees(neighborRegion.degrees);
            }

            var neighborRegionsArray:Array = [];
            for each (neighborRegion in neighborRegions)
                neighborRegionsArray.push(neighborRegion);
            neighborRegionsArray.sort(Sort.sortByCompareValueAndSettlementCellIndex);

            analysis.neighborRegions = neighborRegionsArray;

            var rand:Rand = new Rand(1);
            if (neighborRegions.length > 0) {
                neighborRegion = neighborRegionsArray[0];
                if (neighborRegionsArray[0].compare == 1 && !neighborRegionsArray[0].nameBinding) {
                    if (rand.next() < .6) {
                        // 60% chance to name-bind the regions
                        region.nameBoundChild = neighborRegion.region;
                        neighborRegion.region.nameBoundParent = region;
                        region.nameBoundChildCompassDirection = Util.oppositeCompassDirection(neighborRegion.compassDirection);
                        neighborRegion.region.nameBoundParentCompassDirection = neighborRegion.compassDirection;
                    }
                }
            }

            return analysis;
        }

        public function nameRegions(regions:Object):void {
            var rand:Rand = new Rand(1);
            var regionsArray:Array = [];
            for each (var region:Object in regions)
                regionsArray.push(region);
            regionsArray.sort(Sort.sortByCellCountAndSettlementCellIndex);

            for each (region in regionsArray)
                region.analysis = analyzeRegionProperties(region.cells);

            for each (region in regionsArray)
                region.analysis = analyzeRegionContext(region);

            for each (region in regionsArray)
                region.name = generateRegionName(region.analysis, new Rand(int(rand.next() * 9999))).name;
        }

        public function generateRegionName(analysis:Object, rand:Rand):Object {
            var prefix:String;
            var suffix:String;

            // Analysis keys
            var analysisKeys:Array = [];
            for (var key:String in analysis)
                analysisKeys.push(key);

            // Prefix keys
            var prefixKeys:Array = [];
            for (key in prefixesByContext)
                prefixKeys.push(key);

            // Suffix keys
            var suffixKeys:Array = [];
            for (key in suffixesByContext)
                suffixKeys.push(key);

            // Possible keys
            var possiblePrefixKeys:Array = Util.sharedPropertiesBetweenArrays(analysisKeys, prefixKeys);
            var possibleSuffixKeys:Array = Util.sharedPropertiesBetweenArrays(analysisKeys, suffixKeys);

            // Possible prefixes
            var possiblePrefixes:Array = [];
            for each (var possiblePrefixKey:String in possiblePrefixKeys) {
                if (prefixesByContext[possiblePrefixKey] && prefixesByContext[possiblePrefixKey].length > 0) {
                    var possiblePrefixVariations:Array = prefixesByContext[possiblePrefixKey];
                    for each (var possiblePrefix:Object in possiblePrefixVariations) {
                        possiblePrefixes.push(possiblePrefix);
                        possiblePrefix.context = possiblePrefixKey;
                    }
                }
            }

            // Possible suffixes
            var possibleSuffixes:Array = [];
            for each (var possibleSuffixKey:String in possibleSuffixKeys)
                possibleSuffixes = possibleSuffixes.concat(suffixesByContext[possibleSuffixKey]);

            // Possible combinations
            var possibleCombinations:Array = [];
            for each (possiblePrefix in possiblePrefixes) {
                for each (var namingGroupIndex:int in possiblePrefix.suffixNamingGroups) {
                    var possibleSuffixesForPrefix:Array = Util.sharedPropertiesBetweenArrays(possibleSuffixes, suffixesByNamingGroup[namingGroupIndex]);
                    if (possibleSuffixesForPrefix.length > 0) {
                        var vettedSuffixesForPrefix:Array = [];

                        for each (var unvettedSuffix:String in possibleSuffixesForPrefix) {
                            if (isValidPlaceName(possiblePrefix.name, unvettedSuffix)) {
                                vettedSuffixesForPrefix.push(unvettedSuffix);
                            }
                        }

                        for each (var vettedSuffix:String in vettedSuffixesForPrefix) {
                            possibleCombinations.push({prefix: possiblePrefix.name, suffix: vettedSuffix});
                            break;
                        }
                    }
                }
            }

            // Choose from possible combinations
            possibleCombinations = Util.removeDuplicatesFromArray(possibleCombinations);
            possibleCombinations.sort(shuffleSort);
            var choice:Object;
            do {
                if (possibleCombinations.length > 0)
                    choice = possibleCombinations.shift();
                else
                    break;
            } while (choice && existingNames.indexOf(choice.prefix + choice.suffix) > -1);
            trace("choice: " + choice.prefix + choice.suffix);

            prefix = choice ? choice.prefix : "...";
            suffix = choice ? choice.suffix : "...";

            if (choice)
                existingNames.push(choice.prefix + choice.suffix);

            return {prefix: prefix, suffix: suffix, name: prefix + suffix};

            function shuffleSort(n1:*, n2:*):int {
                return (rand.next() > .5) ? 1 : -1;
            }
        }

        public function nameLands(lands:Object):void {
            var rand:Rand = new Rand(1);
            for each (var land:Object in lands) {
                land.analysis = analyzeLand(land.cells);
                // Name land
                if (land.analysis["tinyIsland"])
                    land.name = "Tiny Island";
                if (land.analysis["smallIsland"])
                    land.name = "Small Island";
                if (land.analysis["largeIsland"])
                    land.name = "Large Island";
                if (land.analysis["continent"])
                    land.name = "Continent";
            }
        }

        private function isValidPlaceName(prefix:String,
                                          suffix:String):Boolean {
            var vowels:String = "aeiouyw";
            if ((isVowel(prefix.charAt(prefix.length - 1)) && isVowel(suffix.charAt(0)))) {
                return false;
            }

            if (hasThreeConsecutiveCharacters(prefix + suffix)) {
                return false;
            }

            if (prefix.charAt(prefix.length - 1) == "t" && suffix.charAt(0) == "h") {
                return false;
            }

            return true;

            function hasThreeConsecutiveCharacters(s:String):Boolean {
                return s.match(/([a-z])\1\1+/g).length > 0;
            }


            function isVowel(c:String):Boolean {
                return vowels.indexOf(c) >= 0;
            }
        }

        public function reset():void {
            existingNames = [];
        }
    }
}
