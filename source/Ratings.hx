import flixel.FlxG;

class Ratings
{
	public static function getLetterRankFromAcc(?accuracy:Float = 0) // generate a letter ranking
	{
		var ranking = "N/A";
		var wifeConditions:Array<Bool> = [
			accuracy > 100, // SS
			accuracy == 100, // fucking amazing
			accuracy >= 99, // SS
			accuracy >= 95, // S
			accuracy >= 90, // A
			accuracy >= 80, // B
			accuracy >= 70, // back to C
			accuracy >= 69, // nice
			accuracy >= 60, // C
			accuracy >= 50, // D
			accuracy >= 40, // F
			accuracy >= 30, // FU
			accuracy >= 20, // FUC
			accuracy >= 10, // FUCK
			accuracy > 0, // oh
			accuracy == 0, // N/A
			accuracy < 0, // bot moment


		];
		for(i in 0...wifeConditions.length)
		{
			var b = wifeConditions[i];
			if (b)
			{
				switch(i)
				{
					case 0:
						ranking = "Perfectly legit";
					case 1:
						ranking = "Perfect!";
					case 2:
						ranking = "SS";
					case 3:
						ranking = "S";
					case 4:
						ranking = "A";
					case 5:
						ranking = "B";
					case 6:
						ranking = "C";
					case 7:
						ranking = "Nice";
					case 8:
						ranking = "C";
					case 9:
						ranking = "D";
					case 10:
						ranking = "F";
					case 11:
						ranking = "FU";
					case 12:
						ranking = "FUC";
					case 13:
						ranking = "FUCK";
					case 14:
						ranking = "afk";
					case 15:
						ranking = "N/A";
					case 16:
						ranking = "botplay";
				}
				break;
			}
		}
		return ranking;
	}
	public static function GenerateLetterRank(accuracy:Float) // generate a letter ranking
	{
		var ranking:String = "N/A";
		if(FlxG.save.data.botplay)
			ranking = "BotPlay";

		if (PlayState.misses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods == 0) // Marvelous (SICK) Full Combo
			ranking = "(MFC)";
		else if (PlayState.misses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods >= 1) // Good Full Combo (Nothing but Goods & Sicks)
			ranking = "(GFC)";
		else if (PlayState.misses == 0) // Regular FC
			ranking = "(FC)";
		else if (PlayState.misses < 10) // Single Digit Combo Breaks
			ranking = "(SDCB)";
		else
			ranking = "(Clear)";

		// WIFE TIME :)))) (based on Wife3)

		var wifeConditions:Array<Bool> = [
			accuracy >= 100.1, // SS
			accuracy >= 99, // SS
			accuracy >= 95, // S
			accuracy >= 90, // A
			accuracy >= 80, // B
			accuracy >= 70, // back to C
			accuracy >= 69, // nice
			accuracy >= 60, // C
			accuracy >= 50, // D
			accuracy > 2, // F
			accuracy > 0, // F
			accuracy < 0, // F
		];

		for(i in 0...wifeConditions.length)
		{
			var b = wifeConditions[i];
			if (b)
			{
				switch(i)
				{
					case 0:
						ranking += " Perfectly Legit";
					case 1:
						ranking += " SS";
					case 2:
						ranking += " S";
					case 3:
						ranking += " A";
					case 4:
						ranking += " B";
					case 5:
						ranking += " C";
					case 6:
						ranking += " Nice";
					case 7:
						ranking += " C";
					case 8:
						ranking += " D";
					case 9:
						ranking += " F";
					case 10:
						ranking += " AFK";
					case 11:
						ranking += " BotPlay";
				}
				break;
			}
		}

		if (accuracy == 0)
			ranking = "N/A";
		else if(FlxG.save.data.botplay)
			ranking = "BotPlay";

		return ranking;
	}
	
	public static function CalculateRating(noteDiff:Float, ?customSafeZone:Float):String // Generate a judgement through some timing shit
	{

		var customTimeScale = Conductor.timeScale;

		if (customSafeZone != null)
			customTimeScale = customSafeZone / 166;
		
		if (noteDiff > 156 * customTimeScale) // so god damn early its a miss
			return "miss";
		if (noteDiff > 125 * customTimeScale) // way early
			return "shit";
		if (noteDiff > 90 * customTimeScale) // early
			return "bad";
		if (noteDiff > 45 * customTimeScale) // your kinda there
			return "good";
		if (noteDiff < -45 * customTimeScale) // little late
			return "good";
		if (noteDiff < -90 * customTimeScale) // late
			return "bad";
		if (noteDiff < -125 * customTimeScale) // late as fuck
			return "shit";
		if (noteDiff < -156 * customTimeScale) // so god damn late its a miss
			return "miss";
		return "sick";
	}


	public static function CalculateRanking(score:Int,scoreDef:Int,nps:Int,maxNPS:Int,accuracy:Float):String
	{
		return switch(FlxG.save.data.songInfo){
			case 0:(FlxG.save.data.npsDisplay ? "NPS: " + nps + " (Max " + maxNPS + ")" : "") +                // NPS Toggle
				" | Score:" + (Conductor.safeFrames != 10 ? score + " (" + scoreDef + ")" : "" + score) +                               // Score
				" | Combo:" + PlayState.combo + (PlayState.combo < PlayState.maxCombo ? " (Max " + PlayState.maxCombo + ")" : "") +
				" | Combo Breaks:" + PlayState.misses + 																				// Misses/Combo Breaks
				"\n | Accuracy:" + (FlxG.save.data.botplay ? "N/A" : HelperFunctions.truncateFloat(accuracy, 2) + " %") +  				// Accuracy
				"| " + GenerateLetterRank(accuracy) + " |";
			case 1:(FlxG.save.data.npsDisplay ? "NPS: " + nps + " (Max " + maxNPS + ")" : "") +                // NPS Toggle
				"\nScore: " + (Conductor.safeFrames != 10 ? score + " (" + scoreDef + ")" : "" + score) +                               // Score
				"\nCombo: " + PlayState.combo + (PlayState.combo < PlayState.maxCombo ? " (Max " + PlayState.maxCombo + ")" : "") +
				"\nCombo Breaks: " + PlayState.misses + 																				// Misses/Combo Breaks
				"\nAccuracy: " + (FlxG.save.data.botplay ? "N/A" : HelperFunctions.truncateFloat(accuracy, 2) + " %") +  				// Accuracy
				"\nRank: " + GenerateLetterRank(accuracy); 
			case 2:(FlxG.save.data.npsDisplay ? "NPS: " + nps + " (Max " + maxNPS + ")" : "") +                // NPS Toggle
				"\nScore: " + (Conductor.safeFrames != 10 ? score + " (" + scoreDef + ")" : "" + score) +                               // Score
				"\nCombo: " + PlayState.combo + (PlayState.combo < PlayState.maxCombo ? " (Max " + PlayState.maxCombo + ")" : "") +
				"\nCombo Breaks/Misses: " + PlayState.misses + 																				// Misses/Combo Breaks
				'\nSicks: ${PlayState.sicks}\nGoods: ${PlayState.goods}\nBads: ${PlayState.bads}\nShits: ${PlayState.shits}'+
				"\nAccuracy: " + (FlxG.save.data.botplay ? "N/A" : HelperFunctions.truncateFloat(accuracy, 2) + " %") +  				// Accuracy
				"\nRank: " + GenerateLetterRank(accuracy); 
			case 3:'Misses:${PlayState.misses}    Score:' + (Conductor.safeFrames != 10 ? score + " (" + scoreDef + ")" : "" + score);
			default:"";

		}
	}

	public static function getDistanceFloat(time:Float):Float{
		var _rating = Math.abs(time / (166 * Conductor.timeScale));
	
		return 1 - (Math.floor(_rating * 100) * 0.01);
	}

	
	public static function getDefRating(rating:String):Float{
		switch(rating.toLowerCase()){
			case "sick": return 0.72;
			case "good": return 0.45;
			case "bad":  return 0.27;
			case "shit": return 0.17;
		}
		return 0.0;
	}
	public static var ratings:Map<String,()->Float  > = [
		"sick" => function():Float return FlxG.save.data.judgeSick,
		"good" => function():Float return FlxG.save.data.judgeGood,
		"bad" =>  function():Float return FlxG.save.data.judgeBad,
		"shit" => function():Float return FlxG.save.data.judgeShit
	];
	public static function ratingMS(?rating:String = "",?amount:Float = 0.0):Float{
		if(amount == 0.0){
			amount = ratings[rating.toLowerCase()]();
		}
		return Math.round((1 - amount) * (166 * Conductor.timeScale));
	}
	public static function ratingFromDistance(dist:Float){
		// var dist = getDistanceFloat(distance);
		var rat:Float = 0;
		for (rating in ['sick','good','bad','shit']){
			rat = ratings[rating]();
			if(dist > rat){
				return rating;
			}
		}
		return "miss";
	}
}
