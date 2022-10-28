package;

import flixel.FlxSprite;

class Checkers extends FlxSprite
{
    public static var leftCheckers:String = 'menuCheckers/left_checkers';
	public static var lowerCheckers:String = 'menuCheckers/lower_checkers';
	public static var upperCheckers:String = 'menuCheckers/upper_checkers';
	public static var rightCheckers:String = 'menuCheckers/right_checkers';

    private var isObject:Bool = false;

    private static function getSide(side:String):String {
        return switch (side.toUpperCase()) {
            case 'L' | 'LEFT': leftCheckers;
            case 'D' | 'DOWN' | 'LOWER': lowerCheckers;
            case 'U' | 'UP' | 'UPPER': upperCheckers;
            case 'R' | 'RIGHT': rightCheckers;
            
            default: leftCheckers;
        }
    }

    // LOL I LOVE CREATING DOCUMENTATION
    /**
     * Creates a new Checkers sprite
     * @param x The `x` of the checkers sprite
     * @param y The `y` of the checkers sprite
     * @param side Which side the checkers sprite are at: `L`/`LEFT`, `D`/`DOWN`/`LOWER`, `U`/`UP`/`UPPER`, `R`/`RIGHT`
     */
    public function new(?x:Float = 0, ?y:Float = 0, ?side:String = 'LEFT')
    {
        super(x, y);
        this.isObject = true;

        changeSide(side);

        scrollFactor.set();

        centerOrigin();
        screenCenter();

        antialiasing = ClientPrefs.globalAntialiasing;
    }

    /**
     * Changes the Checkers sprite's side
     * @param side The side to change to: `L`/`LEFT`, `D`/`DOWN`/`LOWER`, `U`/`UP`/`UPPER`, `R`/`RIGHT`
     */
    public function changeSide(?side:String = 'LEFT') {
        if (isObject) loadGraphic(Paths.image(getSide(side)));
    }

}