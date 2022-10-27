package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.3'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camBG:FlxCamera;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	private var camTrans:FlxCamera;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		'gallery',
		#if !switch 'donate', #end
		'options'
	];

	var optionColors:Map<String, Int> = [
		'story_mode' 						=> 0xFF875ADB,
		'freeplay' 							=> 0xFFDB4F4F,
		#if MODS_ALLOWED 'mods' 			=> 0xFF4D94FF, #end
		#if ACHIEVEMENTS_ALLOWED 'awards' 	=> 0xFFF550DF, #end
		'credits' 							=> 0xFF51DB53,
		'gallery' 							=> 0xFFF3E84F,
		#if !switch 'donate' 				=> 0xFFECA918, #end
		'options' 							=> 0xFF8CDBD1
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var bg:FlxSprite;
	var bGraphic:FlxSprite;
	var checkers:FlxSprite;

	override function create()
	{
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camBG = new FlxCamera();
		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camTrans = new FlxCamera();
		camBG.bgColor.alpha = 0;
		camGame.bgColor.alpha = 0;
		camAchievement.bgColor.alpha = 0;
		camTrans.bgColor.alpha = 0;

		FlxG.cameras.add(camBG, false);
		FlxG.cameras.add(camGame, false);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.add(camTrans, true);
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		//var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		//bg.setGraphicSize(Std.int(bg.width * 1.175));
		//bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.cameras = [camBG];
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		/*
		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);
		
		// magenta.scrollFactor.set();*/

		// BLACK GRAPHIC
		bGraphic = new FlxSprite().makeGraphic(100, FlxG.height, FlxColor.BLACK);
		bGraphic.scrollFactor.set();
		bGraphic.cameras = [camBG];
		add(bGraphic);

		// CHECKERS
		checkers = new FlxSprite().loadGraphic(Paths.leftCheckers);

		checkers.scrollFactor.set();

		checkers.centerOrigin();
		checkers.screenCenter();

		checkers.antialiasing = ClientPrefs.globalAntialiasing;

		checkers.cameras = [camBG];

		checkers.x = -500;

		add(checkers);

		FlxTween.tween(checkers, {x: 0}, 1.5, {ease: FlxEase.backOut, startDelay: 0});
		
		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		camGame.x = -500;
		FlxTween.tween(camGame, {x: 0}, 1.5, {ease: FlxEase.sineOut, startDelay: 0});

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;

			// MENU ITEM
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);

			menuItem.scale.x = scale;
			menuItem.scale.y = scale;

			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');

			menuItem.cameras = [camGame];

			menuItem.ID = i;

			//menuItem.screenCenter(X);
			menuItems.add(menuItem);

			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);

			menuItem.antialiasing = ClientPrefs.globalAntialiasing;

			menuItem.updateHitbox();

			menuItem.origin.x = 0;
			menuItem.x = 0;

			// Pre tween
			menuItem.alpha = 0;

			FlxTween.tween(menuItem, {alpha: 1}, 1.5, {ease: FlxEase.sineOut, startDelay: 0.5});

			if (optionShit[i] == 'gallery') { menuItem.scale.set(0.9, 0.9); menuItem.updateHitbox(); menuItem.x += 30; menuItem.y -= 15; }
		}

		camGame.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.cameras = [camGame];
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.cameras = [camGame];
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					//if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{

						FlxTween.tween(checkers, {x: -500}, 2, {ease: FlxEase.backIn, startDelay: 0});

						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'gallery':
										MusicBeatState.switchState(new MainMenuState());
									case 'options':
										LoadingState.loadAndSwitchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
		/*
		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});*/
	}

	var zoomTween:FlxTween;
	var colorTween:FlxTween;

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		// ZOOM CAMERA

		FlxG.camera.zoom = 1.1;
		if(zoomTween != null) zoomTween.cancel();
			zoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, 0.5, {ease: FlxEase.circOut, onComplete: function(twn:FlxTween)
			{
				zoomTween = null;
			}
		});
		
		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		// TWEEN COLOR

		if (colorTween != null)
			colorTween.cancel();

		colorTween = FlxTween.color(bg, ClientPrefs.flashing ? 0.25 : 1.0, bg.color, optionColors[optionShit[curSelected]], {ease: FlxEase.sineOut});

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();
			spr.origin.x = 0;
			spr.x = 0;

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				spr.width = Math.abs(spr.scale.x) * spr.frameWidth; // thank you flixel
				spr.origin.x = 0;
				spr.x = 10;

				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}
}
