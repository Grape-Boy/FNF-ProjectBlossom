package editors;

import openfl.sensors.Accelerometer;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.system.FlxSound;
import openfl.utils.Assets;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.ui.FlxButton;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flash.net.FileFilter;
import lime.system.Clipboard;
import haxe.Json;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import WeekData;

using StringTools;

class WeekEditorState extends MusicBeatState
{
	var bgSprite:FlxSprite;

	var weekIcon:FlxSprite;

	//var txtTracklist:FlxText;
	//var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var lowerCheckers:FlxSprite;
	var blackUnderlay:FlxSprite;
	var weekThing:MenuItem;
	var lock:FlxSprite;
	var upperCheckers:FlxSprite;

	var txtWeekTitle:FlxText;

	var missingFileText:FlxText;

	var weekFile:WeekFile = null;
	public function new(weekFile:WeekFile = null)
	{
		super();
		this.weekFile = WeekData.createWeekFile();
		if(weekFile != null) this.weekFile = weekFile;
		else weekFileName = 'week1';
	}

	override function create() {
		txtWeekTitle = new FlxText(10, 48, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		//txtWeekTitle.alpha = 0.7;
		
		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		//var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bgSprite.scrollFactor.set();
		bgSprite.screenCenter();
		bgSprite.antialiasing = ClientPrefs.globalAntialiasing;
		FlxTween.color(bgSprite, 0.0, FlxColor.WHITE, FlxColor.fromRGB(146, 113, 253));
		add(bgSprite);

		weekIcon = new FlxSprite();
		weekIcon.antialiasing = ClientPrefs.globalAntialiasing;
		add(weekIcon);

		lowerCheckers = new Checkers(0, 0, 'LOWER');
		add(lowerCheckers);

		blackUnderlay = new FlxSprite().makeGraphic(475, FlxG.height, FlxColor.fromString('0x40000000'));
		blackUnderlay.x = FlxG.width - blackUnderlay.width;
		add(blackUnderlay);

		weekThing = new MenuItem(0, bgSprite.y + 396, weekFileName);
		weekThing.y += weekThing.height + 20;
		weekThing.antialiasing = ClientPrefs.globalAntialiasing;
		add(weekThing);

		/*var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);*/
		
		//grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		
		lock = new FlxSprite();
		lock.frames = ui_tex;
		lock.animation.addByPrefix('lock', 'lock');
		lock.animation.play('lock');
		lock.antialiasing = ClientPrefs.globalAntialiasing;
		add(lock);

		upperCheckers = new Checkers(0, 0, 'UPPER');
		add(upperCheckers);
		
		missingFileText = new FlxText(0, 0, FlxG.width, "");
		missingFileText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingFileText.borderSize = 2;
		missingFileText.visible = false;
		add(missingFileText); 
		
		/*var charArray:Array<String> = weekFile.weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}*/

		//add(bgYellow);
		//add(grpWeekCharacters);

		/*var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgSprite.y + 435).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.globalAntialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.font("vcr.ttf");
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);*/
		add(txtWeekTitle);

		addEditorBox();
		reloadAllShit();

		FlxG.mouse.visible = true;

		super.create();
	}

	var UI_box:FlxUITabMenu;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	function addEditorBox() {
		var tabs = [
			{name: 'Week', label: 'Week'},
			{name: 'Other', label: 'Other'},
			{name: 'Icon', label: 'Icon'},
		];
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(375, 375);
		UI_box.x = FlxG.width - UI_box.width;
		//UI_box.y = FlxG.height - UI_box.height;
		UI_box.scrollFactor.set();
		addWeekUI();
		addOtherUI();
		addIconUI();
		
		UI_box.selected_tab_id = 'Week';
		add(UI_box);

		var loadWeekButton:FlxButton = new FlxButton(0, 650, "Load Week", function() {
			loadWeek();
		});
		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);
		
		var freeplayButton:FlxButton = new FlxButton(0, 650, "Freeplay", function() {
			MusicBeatState.switchState(new WeekEditorFreeplayState(weekFile));
			
		});
		freeplayButton.screenCenter(X);
		add(freeplayButton);
	
		var saveWeekButton:FlxButton = new FlxButton(0, 650, "Save Week", function() {
			saveWeek(weekFile);
		});
		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);
	}

	var songsInputText:FlxUIInputText;
	var backgroundInputText:FlxUIInputText;
	var displayNameInputText:FlxUIInputText;
	var weekNameInputText:FlxUIInputText;
	var weekFileInputText:FlxUIInputText;
	
	var opponentInputText:FlxUIInputText;
	var boyfriendInputText:FlxUIInputText;
	var girlfriendInputText:FlxUIInputText;

	var hideCheckbox:FlxUICheckBox;
	
	var weekPNGInputText:FlxUIInputText;
	var useWeekNameCheckbox:FlxUICheckBox;

	public static var weekFileName:String = 'week1';
	
	function addWeekUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Week";

		//blockPressWhileTypingOn.push();
		
		songsInputText = new FlxUIInputText(10, 30, 200, '', 8);
		blockPressWhileTypingOn.push(songsInputText);

		opponentInputText = new FlxUIInputText(10, songsInputText.y + 40, 70, '', 8);
		blockPressWhileTypingOn.push(opponentInputText);
		boyfriendInputText = new FlxUIInputText(opponentInputText.x + 75, opponentInputText.y, 70, '', 8);
		blockPressWhileTypingOn.push(boyfriendInputText);
		girlfriendInputText = new FlxUIInputText(boyfriendInputText.x + 75, opponentInputText.y, 70, '', 8);
		blockPressWhileTypingOn.push(girlfriendInputText);

		backgroundInputText = new FlxUIInputText(10, opponentInputText.y + 40, 120, '', 8);
		blockPressWhileTypingOn.push(backgroundInputText);
		

		displayNameInputText = new FlxUIInputText(10, backgroundInputText.y + 60, 200, '', 8);
		blockPressWhileTypingOn.push(backgroundInputText);

		weekNameInputText = new FlxUIInputText(10, displayNameInputText.y + 60, 150, '', 8);
		blockPressWhileTypingOn.push(weekNameInputText);

		weekFileInputText = new FlxUIInputText(10, weekNameInputText.y + 40, 100, '', 8);
		blockPressWhileTypingOn.push(weekFileInputText);
		reloadWeekThing();

		hideCheckbox = new FlxUICheckBox(10, weekFileInputText.y + 40, null, null, "Hide Week from Story Mode?", 100);
		hideCheckbox.callback = function()
		{
			weekFile.hideStoryMode = hideCheckbox.checked;
		};

		weekPNGInputText = new FlxUIInputText(weekFileInputText.x + 120, weekFileInputText.y, 200, '', 8);
		blockPressWhileTypingOn.push(weekPNGInputText);

		useWeekNameCheckbox = new FlxUICheckBox(weekPNGInputText.x, hideCheckbox.y, null, null, "Use Week File Name for WeekPNG", 100);
		useWeekNameCheckbox.callback = function()
		{
			weekFile.useWeekName = useWeekNameCheckbox.checked;
			reloadWeekThing();
		};

		tab_group.add(new FlxText(songsInputText.x, songsInputText.y - 18, 0, 'Songs:'));
		tab_group.add(new FlxText(opponentInputText.x, opponentInputText.y - 18, 0, '[UNUSED] Characters:'));
		tab_group.add(new FlxText(backgroundInputText.x, backgroundInputText.y - 18, 0, '[UNUSED] Background Asset:'));
		tab_group.add(new FlxText(displayNameInputText.x, displayNameInputText.y - 18, 0, 'Display Name:'));
		tab_group.add(new FlxText(weekNameInputText.x, weekNameInputText.y - 18, 0, 'Week Name (for Reset Score Menu):'));
		tab_group.add(new FlxText(weekFileInputText.x, weekFileInputText.y - 18, 0, 'Week File:'));
		tab_group.add(new FlxText(weekPNGInputText.x, weekPNGInputText.y - 18, 0, 'Week Name File:'));

		tab_group.add(songsInputText);
		tab_group.add(opponentInputText);
		tab_group.add(boyfriendInputText);
		tab_group.add(girlfriendInputText);
		tab_group.add(backgroundInputText);

		tab_group.add(displayNameInputText);
		tab_group.add(weekNameInputText);
		tab_group.add(weekFileInputText);
		tab_group.add(hideCheckbox);
		
		tab_group.add(weekPNGInputText);
		tab_group.add(useWeekNameCheckbox);
		UI_box.addGroup(tab_group);
	}

	var weekBeforeInputText:FlxUIInputText;
	var difficultiesInputText:FlxUIInputText;
	var lockedCheckbox:FlxUICheckBox;
	var hiddenUntilUnlockCheckbox:FlxUICheckBox;

	var rBGStepper:FlxUINumericStepper;
	var gBGStepper:FlxUINumericStepper;
	var bBGStepper:FlxUINumericStepper;

	function updateBG() {
		weekFile.storyMenuColor[0] = Math.round(rBGStepper.value);
		weekFile.storyMenuColor[1] = Math.round(gBGStepper.value);
		weekFile.storyMenuColor[2] = Math.round(bBGStepper.value);

		var col:Array<Int> = weekFile.storyMenuColor;
		bgSprite.color = FlxColor.fromRGB(col[0], col[1], col[2]);
	}

	function addOtherUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Other";

		lockedCheckbox = new FlxUICheckBox(10, 30, null, null, "Week starts Locked", 100);
		lockedCheckbox.callback = function()
		{
			weekFile.startUnlocked = !lockedCheckbox.checked;
			lock.visible = lockedCheckbox.checked;
			hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (lockedCheckbox.checked ? 1 : 0);
		};

		hiddenUntilUnlockCheckbox = new FlxUICheckBox(10, lockedCheckbox.y + 25, null, null, "Hidden until Unlocked", 110);
		hiddenUntilUnlockCheckbox.callback = function()
		{
			weekFile.hiddenUntilUnlocked = hiddenUntilUnlockCheckbox.checked;
		};
		hiddenUntilUnlockCheckbox.alpha = 0.4;

		weekBeforeInputText = new FlxUIInputText(10, hiddenUntilUnlockCheckbox.y + 55, 100, '', 8);
		blockPressWhileTypingOn.push(weekBeforeInputText);

		difficultiesInputText = new FlxUIInputText(10, weekBeforeInputText.y + 60, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesInputText);

		rBGStepper = new FlxUINumericStepper(10, difficultiesInputText.y + 100, 20, 255, 0, 255, 0);
		gBGStepper = new FlxUINumericStepper(80, rBGStepper.y, 20, 255, 0, 255, 0);
		bBGStepper = new FlxUINumericStepper(150, rBGStepper.y, 20, 255, 0, 255, 0);
		
		tab_group.add(new FlxText(weekBeforeInputText.x, weekBeforeInputText.y - 28, 0, 'Week File name of the Week you have\nto finish for Unlocking:'));
		tab_group.add(new FlxText(difficultiesInputText.x, difficultiesInputText.y - 20, 0, 'Difficulties:'));
		tab_group.add(new FlxText(difficultiesInputText.x, difficultiesInputText.y + 20, 0, 'Default difficulties are "Easy, Normal, Hard"\nwithout quotes.'));
		tab_group.add(new FlxText(10, rBGStepper.y - 20, 0, 'BG Color R/G/B:'));
		tab_group.add(weekBeforeInputText);
		tab_group.add(difficultiesInputText);
		tab_group.add(hiddenUntilUnlockCheckbox);
		tab_group.add(lockedCheckbox);
		tab_group.add(rBGStepper);
		tab_group.add(gBGStepper);
		tab_group.add(bBGStepper);
		UI_box.addGroup(tab_group);
	}

	var weekIconInput:FlxUIInputText;
	var weekIconXInput:FlxUINumericStepper;
	var weekIconYInput:FlxUINumericStepper;
	var iconFMultStepper:FlxUINumericStepper;
	var iconFIncStepper:FlxUINumericStepper;

	var lockIconCheckbox:FlxUICheckBox; // this is for making the icon stop moving in the week editor

	function addIconUI() {
		var tab_group:FlxUI = new FlxUI(null, UI_box);
		tab_group.name = "Icon";
		
		weekIconInput = new FlxUIInputText(10, 40, 200, weekFile.weekIcon, 8);
		blockPressWhileTypingOn.push(weekIconInput);
		
		weekIconXInput = new FlxUINumericStepper(10, 80, 10, weekFile.iconPositions[0], -4096, 4096, 2);
		weekIconYInput = new FlxUINumericStepper(80, 80, 10, weekFile.iconPositions[1], -4096, 4096, 2);

		lockIconCheckbox = new FlxUICheckBox(10, 300, null, null, "Lock Icon? (Editor Only)", 150);
		lockIconCheckbox.callback = function()
		{
			isIconLocked = lockIconCheckbox.checked;
		};

		iconFMultStepper = new FlxUINumericStepper(10, 140, 0.1, weekFile.iconFloatMult, 0, 100, 2);
		iconFIncStepper = new FlxUINumericStepper(100, 140, 0.005, weekFile.iconFloatInc, 0, 1, 3, 1, new FlxUIInputText(0, 0, 35));

		//tab_group.add();
		//tab_group.add(new FlxText());
		tab_group.add(new FlxText(weekIconInput.x, weekIconInput.y - 18, 0, 'Week Icon:'));
		tab_group.add(new FlxText(weekIconXInput.x, weekIconXInput.y - 18, 0, 'Icon X:'));
		tab_group.add(new FlxText(weekIconYInput.x, weekIconYInput.y - 18, 0, 'Icon Y:'));
		tab_group.add(new FlxText(iconFMultStepper.x, iconFMultStepper.y - 18, 0, 'Icon Float Mult:'));
		tab_group.add(new FlxText(iconFIncStepper.x, iconFIncStepper.y - 18, 0, 'Icon Float Speed:'));

		tab_group.add(weekIconInput);
		tab_group.add(weekIconXInput);
		tab_group.add(weekIconYInput);

		tab_group.add(iconFMultStepper);
		tab_group.add(iconFIncStepper);

		tab_group.add(lockIconCheckbox);
		UI_box.addGroup(tab_group);
	}

	function updateIcon()
	{
		weekIcon.visible = true;
		var assetName:String = weekFile.weekIcon;
		var pos:Array<Float> = weekFile.iconPositions;
		if(assetName == null || assetName.length < 1 || Paths.image('menuicons/' + assetName) == null) {
			weekIcon.visible = false;
		} else {
			weekIcon.loadGraphic(Paths.image('menuicons/' + assetName));
			weekIcon.updateHitbox();
			
			weekIcon.x = pos[0]; weekIcon.y = pos[1];
			iconX = pos[0]; iconY = pos[1];
		}
	}

	//Used on onCreate and when you load a week
	function reloadAllShit() {
		var weekString:String = weekFile.songs[0][0];
		for (i in 1...weekFile.songs.length) {
			weekString += ', ' + weekFile.songs[i][0];
		}
		// WEEK
		songsInputText.text = weekString;
		backgroundInputText.text = weekFile.weekBackground;
		displayNameInputText.text = weekFile.storyName;
		weekNameInputText.text = weekFile.weekName;
		weekFileInputText.text = weekFileName;
		
		opponentInputText.text = weekFile.weekCharacters[0];
		boyfriendInputText.text = weekFile.weekCharacters[1];
		girlfriendInputText.text = weekFile.weekCharacters[2];

		hideCheckbox.checked = weekFile.hideStoryMode;

		weekPNGInputText.text = weekFile.weekPNG;
		
		var tempUseWeekName:Null<Bool> = weekFile.useWeekName;
		if (tempUseWeekName == null) {
			weekFile.useWeekName = true;
			tempUseWeekName = weekFile.useWeekName;
		}
		useWeekNameCheckbox.checked = tempUseWeekName;

		// OTHER
		weekBeforeInputText.text = weekFile.weekBefore;

		difficultiesInputText.text = '';
		if(weekFile.difficulties != null) difficultiesInputText.text = weekFile.difficulties;

		var tempStoryMenuColor:Array<Int> = weekFile.storyMenuColor;
		if (tempStoryMenuColor == null) {
			weekFile.storyMenuColor = [146, 113, 253];
			tempStoryMenuColor = weekFile.storyMenuColor;
			
		}
		rBGStepper.value = tempStoryMenuColor[0];
		gBGStepper.value = tempStoryMenuColor[1];
		bBGStepper.value = tempStoryMenuColor[2];

		// ICON
		var tempIconPositions:Array<Float> = weekFile.iconPositions;
		if (tempIconPositions == null) {
			weekFile.iconPositions = [175, 350];
			tempIconPositions = weekFile.iconPositions;
		}
		weekIconXInput.value = tempIconPositions[0];
		weekIconYInput.value = tempIconPositions[1];

		iconX = weekFile.iconPositions[0];
		iconY = weekFile.iconPositions[1];

		var tempFloatMult:Null<Float> = weekFile.iconFloatMult;
		if (tempFloatMult == null) {
			weekFile.iconFloatMult = 1;
			tempFloatMult = weekFile.iconFloatMult;
		}

		var tempFloatInc:Null<Float> = weekFile.iconFloatInc;
		if (tempFloatInc == null) {
			weekFile.iconFloatInc = 0.025;
			tempFloatInc = weekFile.iconFloatInc;
		}

		floatMult = tempFloatMult;
		angleInc = tempFloatInc;

		iconFMultStepper.value = floatMult;
		iconFIncStepper.value = angleInc;

		lockedCheckbox.checked = !weekFile.startUnlocked;
		lock.visible = lockedCheckbox.checked;
		
		hiddenUntilUnlockCheckbox.checked = weekFile.hiddenUntilUnlocked;
		hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (lockedCheckbox.checked ? 1 : 0);

		//reloadBG();
		reloadWeekThing();
		updateText();
		updateBG();
		updateIcon();
	}

	function updateText()
	{
		txtWeekTitle.text = weekFile.storyName.toUpperCase();
		//txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);
	}
	/*
	function reloadBG() {
		bgSprite.visible = true;
		var assetName:String = weekFile.weekBackground;

		var isMissing:Bool = true;
		if(assetName != null && assetName.length > 0) {
			if( #if MODS_ALLOWED FileSystem.exists(Paths.modsImages('menubackgrounds/menu_' + assetName)) || #end
			Assets.exists(Paths.getPath('images/menubackgrounds/menu_' + assetName + '.png', IMAGE), IMAGE)) {
				bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
				isMissing = false;
			}
		}

		if(isMissing) {
			bgSprite.visible = false;
		}
	}*/

	function reloadWeekThing() {
		weekThing.visible = true;
		missingFileText.visible = false;
		var assetName:String;
		assetName = (weekFile.useWeekName ? weekFileInputText.text.trim() : weekPNGInputText.text.trim());
		
		var isMissing:Bool = true;
		if(assetName != null && assetName.length > 0) {
			if( #if MODS_ALLOWED FileSystem.exists(Paths.modsImages('storymenu/' + assetName)) || #end
			Assets.exists(Paths.getPath('images/storymenu/' + assetName + '.png', IMAGE), IMAGE)) {
				weekThing.loadGraphic(Paths.image('storymenu/' + assetName));
				isMissing = false;
			}
		}

		if(isMissing) {
			weekThing.visible = false;
			missingFileText.visible = true;
			missingFileText.text = 'MISSING FILE: images/storymenu/' + assetName + '.png';
		}
		recalculateStuffPosition();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Week Editor", "Editting: " + weekFileName);
		#end
	}
	
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == weekFileInputText) {
				weekFileName = weekFileInputText.text.trim();
				reloadWeekThing();
			} else if(sender == opponentInputText || sender == boyfriendInputText || sender == girlfriendInputText) {
				weekFile.weekCharacters[0] = opponentInputText.text.trim();
				weekFile.weekCharacters[1] = boyfriendInputText.text.trim();
				weekFile.weekCharacters[2] = girlfriendInputText.text.trim();
				//updateText();
			} else if(sender == backgroundInputText) {
				weekFile.weekBackground = backgroundInputText.text.trim();
				//reloadBG();
			} else if(sender == displayNameInputText) {
				weekFile.storyName = displayNameInputText.text.trim();
				updateText();
			} else if(sender == weekNameInputText) {
				weekFile.weekName = weekNameInputText.text.trim();
			} else if(sender == songsInputText) {
				var splittedText:Array<String> = songsInputText.text.trim().split(',');
				for (i in 0...splittedText.length) {
					splittedText[i] = splittedText[i].trim();
				}

				while(splittedText.length < weekFile.songs.length) {
					weekFile.songs.pop();
				}

				for (i in 0...splittedText.length) {
					if(i >= weekFile.songs.length) { //Add new song
						weekFile.songs.push([splittedText[i], 'dad', [146, 113, 253]]);
					} else { //Edit song
						weekFile.songs[i][0] = splittedText[i];
						if(weekFile.songs[i][1] == null || weekFile.songs[i][1]) {
							weekFile.songs[i][1] = 'dad';
							weekFile.songs[i][2] = [146, 113, 253];
						}
					}
				}
				//updateText();
			} else if(sender == weekBeforeInputText) {
				weekFile.weekBefore = weekBeforeInputText.text.trim();
			} else if(sender == difficultiesInputText) {
				weekFile.difficulties = difficultiesInputText.text.trim();
			} else if(sender == weekPNGInputText) {
				weekFile.weekPNG = weekPNGInputText.text.trim();
				reloadWeekThing();
			} else if(sender == weekIconInput) {
				weekFile.weekIcon = weekIconInput.text.trim();
				updateIcon();
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if(sender == weekIconXInput) {
				weekFile.iconPositions[0] = weekIconXInput.value;
				updateIcon();
			} else if(sender == weekIconYInput) {
				weekFile.iconPositions[1] = weekIconYInput.value;
				updateIcon();
			} else if(sender == iconFMultStepper) {
				weekFile.iconFloatMult = iconFMultStepper.value;
				floatMult = iconFMultStepper.value;
			} else if(sender == iconFIncStepper) {
				weekFile.iconFloatInc = iconFIncStepper.value;
				angleInc = iconFIncStepper.value;
			} else if(sender == rBGStepper || sender == gBGStepper || sender == bBGStepper) {
				updateBG();
			}
		}
	}

	var angle:Float = 0;
	var angleInc:Float = 0.025;
	var radius:Float = 10;

	var iconX:Float = 175;
	var iconY:Float = 350;

	var floatMult:Float = 1;

	var isIconLocked:Bool = false;
	
	override function update(elapsed:Float)
	{
		if(loadedWeek != null) {
			weekFile = loadedWeek;
			loadedWeek = null;

			reloadAllShit();
		}

		if (angle >= 360 || angle <= -360) { // huh sound effect
			angle = 0;
		}
		angle += angleInc;

		weekIcon.x = iconX + (!isIconLocked ? (Math.sin(angle)*radius*Math.cos(angle)) * floatMult : 0);
		weekIcon.y = iconY + (!isIconLocked ? (Math.cos(angle)*radius*Math.sin(angle)) * floatMult : 0);

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;

				if(FlxG.keys.justPressed.ENTER) inputText.hasFocus = false;
				break;
			}
		}

		if(!blockInput) {
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			if(FlxG.keys.justPressed.ESCAPE) {
				MusicBeatState.switchState(new editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		}

		super.update(elapsed);

		weekThing.updateHitbox();
		weekThing.screenCenter(Y);
		weekThing.y += weekThing.height;

		lock.y = weekThing.y;
		missingFileText.y = weekThing.y + 36;
	}

	function recalculateStuffPosition() {
		weekThing.x = FlxG.width - weekThing.width - 10;
		lock.x = weekThing.x - 10 - lock.width;
	}

	private static var _file:FileReference;
	public static function loadWeek() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}
	
	public static var loadedWeek:WeekFile = null;
	public static var loadError:Bool = false;
	private static function onLoadComplete(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				loadedWeek = cast Json.parse(rawJson);
				if(loadedWeek.weekCharacters != null && loadedWeek.weekName != null) //Make sure it's really a week
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					loadError = false;

					weekFileName = cutName;
					_file = null;
					return;
				}
			}
		}
		loadError = true;
		loadedWeek = null;
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
		private static function onLoadCancel(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private static function onLoadError(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	public static function saveWeek(weekFile:WeekFile) {
		var data:String = Json.stringify(weekFile, "\t");
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, weekFileName + ".json");
		}
	}
	
	private static function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
		private static function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private static function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}

class WeekEditorFreeplayState extends MusicBeatState
{
	var weekFile:WeekFile = null;
	public function new(weekFile:WeekFile = null)
	{
		super();
		this.weekFile = WeekData.createWeekFile();
		if(weekFile != null) this.weekFile = weekFile;
	}

	var bg:FlxSprite;
	var leftCheckers:FlxSprite;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<HealthIcon> = [];

	var curSelected = 0;

	override function create() {
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;

		bg.color = FlxColor.WHITE;
		add(bg);

		leftCheckers = new Checkers(0, 0, 'LEFT');
		add(leftCheckers);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...weekFile.songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, weekFile.songs[i][0], true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			songText.snapToPosition();

			var icon:HealthIcon = new HealthIcon(weekFile.songs[i][1]);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		addEditorBox();
		changeSelection();
		super.create();
	}
	
	var UI_box:FlxUITabMenu;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	function addEditorBox() {
		var tabs = [
			{name: 'Freeplay', label: 'Freeplay'},
		];
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(250, 200);
		UI_box.x = FlxG.width - UI_box.width - 100;
		UI_box.y = FlxG.height - UI_box.height - 60;
		UI_box.scrollFactor.set();
		
		UI_box.selected_tab_id = 'Week';
		addFreeplayUI();
		add(UI_box);

		var blackBlack:FlxSprite = new FlxSprite(0, 670).makeGraphic(FlxG.width, 50, FlxColor.BLACK);
		blackBlack.alpha = 0.6;
		add(blackBlack);

		var loadWeekButton:FlxButton = new FlxButton(0, 685, "Load Week", function() {
			WeekEditorState.loadWeek();
		});
		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);
		
		var storyModeButton:FlxButton = new FlxButton(0, 685, "Story Mode", function() {
			MusicBeatState.switchState(new WeekEditorState(weekFile));
			
		});
		storyModeButton.screenCenter(X);
		add(storyModeButton);
	
		var saveWeekButton:FlxButton = new FlxButton(0, 685, "Save Week", function() {
			WeekEditorState.saveWeek(weekFile);
		});
		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);
	}
	
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			weekFile.songs[curSelected][1] = iconInputText.text;
			iconArray[curSelected].changeIcon(iconInputText.text);
		} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if(sender == bgColorStepperR || sender == bgColorStepperG || sender == bgColorStepperB) {
				updateBG();
			}
		}
	}

	var bgColorStepperR:FlxUINumericStepper;
	var bgColorStepperG:FlxUINumericStepper;
	var bgColorStepperB:FlxUINumericStepper;
	var iconInputText:FlxUIInputText;
	function addFreeplayUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Freeplay";

		bgColorStepperR = new FlxUINumericStepper(10, 40, 20, 255, 0, 255, 0);
		bgColorStepperG = new FlxUINumericStepper(80, 40, 20, 255, 0, 255, 0);
		bgColorStepperB = new FlxUINumericStepper(150, 40, 20, 255, 0, 255, 0);

		var copyColor:FlxButton = new FlxButton(10, bgColorStepperR.y + 25, "Copy Color", function() {
			Clipboard.text = bg.color.red + ',' + bg.color.green + ',' + bg.color.blue;
		});
		var pasteColor:FlxButton = new FlxButton(140, copyColor.y, "Paste Color", function() {
			if(Clipboard.text != null) {
				var leColor:Array<Int> = [];
				var splitted:Array<String> = Clipboard.text.trim().split(',');
				for (i in 0...splitted.length) {
					var toPush:Int = Std.parseInt(splitted[i]);
					if(!Math.isNaN(toPush)) {
						if(toPush > 255) toPush = 255;
						else if(toPush < 0) toPush *= -1;
						leColor.push(toPush);
					}
				}

				if(leColor.length > 2) {
					bgColorStepperR.value = leColor[0];
					bgColorStepperG.value = leColor[1];
					bgColorStepperB.value = leColor[2];
					updateBG();
				}
			}
		});

		iconInputText = new FlxUIInputText(10, bgColorStepperR.y + 70, 100, '', 8);

		var hideFreeplayCheckbox:FlxUICheckBox = new FlxUICheckBox(10, iconInputText.y + 30, null, null, "Hide Week from Freeplay?", 100);
		hideFreeplayCheckbox.checked = weekFile.hideFreeplay;
		hideFreeplayCheckbox.callback = function()
		{
			weekFile.hideFreeplay = hideFreeplayCheckbox.checked;
		};
		
		tab_group.add(new FlxText(10, bgColorStepperR.y - 18, 0, 'Selected background Color R/G/B:'));
		tab_group.add(new FlxText(10, iconInputText.y - 18, 0, 'Selected icon:'));
		tab_group.add(bgColorStepperR);
		tab_group.add(bgColorStepperG);
		tab_group.add(bgColorStepperB);
		tab_group.add(copyColor);
		tab_group.add(pasteColor);
		tab_group.add(iconInputText);
		tab_group.add(hideFreeplayCheckbox);
		UI_box.addGroup(tab_group);
	}

	function updateBG() {
		weekFile.songs[curSelected][2][0] = Math.round(bgColorStepperR.value);
		weekFile.songs[curSelected][2][1] = Math.round(bgColorStepperG.value);
		weekFile.songs[curSelected][2][2] = Math.round(bgColorStepperB.value);
		bg.color = FlxColor.fromRGB(weekFile.songs[curSelected][2][0], weekFile.songs[curSelected][2][1], weekFile.songs[curSelected][2][2]);
	}

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = weekFile.songs.length - 1;
		if (curSelected >= weekFile.songs.length)
			curSelected = 0;

		var bullShit:Int = 0;
		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		trace(weekFile.songs[curSelected]);
		iconInputText.text = weekFile.songs[curSelected][1];
		bgColorStepperR.value = Math.round(weekFile.songs[curSelected][2][0]);
		bgColorStepperG.value = Math.round(weekFile.songs[curSelected][2][1]);
		bgColorStepperB.value = Math.round(weekFile.songs[curSelected][2][2]);
		updateBG();
	}

	override function update(elapsed:Float) {
		if(WeekEditorState.loadedWeek != null) {
			super.update(elapsed);
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new WeekEditorFreeplayState(WeekEditorState.loadedWeek));
			WeekEditorState.loadedWeek = null;
			return;
		}
		
		if(iconInputText.hasFocus) {
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];
			if(FlxG.keys.justPressed.ENTER) {
				iconInputText.hasFocus = false;
			}
		} else {
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			if(FlxG.keys.justPressed.ESCAPE) {
				MusicBeatState.switchState(new editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}

			if(controls.UI_UP_P) changeSelection(-1);
			if(controls.UI_DOWN_P) changeSelection(1);
		}
		super.update(elapsed);
	}
}
