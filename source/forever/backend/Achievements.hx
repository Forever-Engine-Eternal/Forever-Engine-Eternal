package forever.backend;

typedef Achievement =
{
    var id:String;
    var displayName:String;
    var description:String;
    var skin:AchievementSkin;
    var sound:String;
}

typedef AchievementSkin =
{
    var popup:SkinableObject;
    var medal:SkinableObject;
    var icon:SkinableObject;
}

typedef SkinableObject =
{
    var ?skin:String;
    var ?scale:Array<Float>;
    var ?color:String;
    var ?flipX:Bool;
    var ?flipY:Bool;
}

class Achievements
{
    public static var achievementsMap:Map<String, Achievement> = [];
    public static var unlockedAchievements:Map<String, Bool> = [];

    @:keep public static function init():Void {
        
        for (achievement in parseAchievementsFromXML(Paths.data("achievements", XML)))
            achievementsMap.set(achievement.id, achievement);

        for (achievement in achievementsMap.keys())
            unlockedAchievements.set(achievement, false);

        loadSavedAchievements();
    }

    @:keep public static function loadSavedAchievements():Void {

        Tools.invokeTempSave(function(save) {
            if (save.data.achievements != null) {
                var savedAchievements:Map<String, Bool> = save.data.achievements;
                for (key in savedAchievements.keys())
                    if (achievementsMap.exists(key))
                        unlockedAchievements.set(key, savedAchievements.get(key));
            }
        }, "achievements");
    }

    @:keep public inline static function saveAchievements():Void {

        Tools.invokeTempSave(function(save) {
            var currentAchievements:Map<String, Bool> = save.data.achievements;
            if (currentAchievements == null)
                currentAchievements = [];

            for (achievement in unlockedAchievements.keys())
                currentAchievements.set(achievement, unlockedAchievements.get(achievement));

            save.data.achievements = currentAchievements;
        }, "achievements");
    }

    @:keep public static function unlockAchievement(achievement:String):Void {

        if (achievementsMap.exists(achievement)) {
            if (unlockedAchievements.get(achievement) != null && unlockedAchievements.get(achievement) == true)
                return;

            unlockedAchievements.set(achievement, true);
            saveAchievements();
        }
        else
            print('Failed unlocked achievement ${achievement}, please check the id!', WARNING);
    }

    @:keep private static function parseAchievementsFromXML(path:String):Array<Achievement> {

        var achievementsArray:Array<Achievement> = [];

        var data = new haxe.xml.Access(Xml.parse(sys.io.File.getContent(path)).firstElement());

        for (node in data.elements) {

            if (node.name == "achievement") {

                if (!node.has.id) {
                    print('An achievement without id has been found, the achievement is ignored. Make sure to set an id to the achievement!', WARNING);
                    continue;
                }

                var achievement:Achievement = {
                    id: node.att.id,
                    displayName: node.has.displayName ? node.att.displayName : node.att.id,
                    description: node.has.description ? node.att.description : "",
                    sound: node.has.sound ? node.att.sound : "confirmMenu",
                    skin: {
                        popup: {skin: "achievementPopup", scale: [1, 1], color: "", flipX: false, flipY: false},
                        medal: {skin: "achievementMedal", scale: [1, 1], color: "", flipX: false, flipY: false},
                        icon: {skin: "", scale: [1, 1], color: "", flipX: false, flipY: false},
                    }
                };

                for (i in node.elements) {
                    switch (i.name) {
                        case "popup": parseSkin(i, achievement.skin.popup);
                        case "medal": parseSkin(i, achievement.skin.medal);
                        case "icon": parseSkin(i, achievement.skin.icon);
                    }
                }

                achievementsArray.push(achievement);
            }
        }

        return achievementsArray;
    }

    private static function parseSkin(att:haxe.xml.Access, defaultSkin:SkinableObject) {
        if (att.has.skin) defaultSkin.skin = att.att.skin;
        if (att.has.scale) defaultSkin.scale = parseSkinScale(att.att.scale);
        if (att.has.color) defaultSkin.color = att.att.color;
        if (att.has.flipX) defaultSkin.flipX = att.att.flipX == "true";
        if (att.has.flipY) defaultSkin.flipY = att.att.flipY == "true";
    }

    private static function parseSkinScale(str:String):Array<Float>
    {
        var scaleArray:Array<Float> = [for (i in str.split(",")) Std.parseInt(i)];
        while (scaleArray.length < 2)
            scaleArray.push(1);

        return scaleArray;
    }
}