/*
 * Copyright 2023 theta-lin
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see https://www.gnu.org/licenses/agpl-3.0.en.html.
 *
 * This project includes code derived from or incorporating the
 * "Musescore Colornotes Hooktheory Plugin"
 * (licensed under the GNU Affero General Public License version 3).
 *
 * Project: Musescore Colornotes Hooktheory Plugin
 * Author: sammik
 * URL: https://github.com/sammik/musescore-plugin-colornotes-hooktheory/blob/main/colornotes_hook_name.qml
 */

import QtQuick 2.6
import QtQuick.Controls 1.4
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Layouts 1.1

MuseScore
{
    version: "1.0"
	menuPath: "Plugins.Fit Scale"
	pluginType: "dock"

	readonly property var toneNames: ["C", "C#/Db", "D", "D#/Eb", "E", "F", "F#/Gb", "G", "G#/Ab", "A", "A#/Bb", "B"]
	readonly property var modeNames: ["Major/Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Minor/Aeolian", "Locrian"]
	readonly property var ionian: [2, 2, 1, 2, 2, 2, 1]

	property var tonalCenter: tonalBox.currentIndex
	property var mode: modalBox.currentIndex

	function applyToSelectedNotes(func)
	{
		if (!curScore) return;

		var fullScore = !(curScore.selection.elements.length > 1);
		if (fullScore)
		{
			cmd("select-all");
			curScore.startCmd();
		}

		var elements = curScore.selection.elements;
		for (var i in elements)
		{
			if (elements[i].type==Element.NOTE)
			{
				func(elements[i]);
			}
		}

		if (fullScore)
		{
			curScore.endCmd();
			cmd("escape");
		}
	}

	function isDiatonic(note, tc, m)
	{
		for (var i = 0, pitch = tc; i < 7; ++i)
		{
			if (note.pitch % 12 == pitch)
			{
				return true;
			}
			pitch = (pitch + ionian[(m + i) % 7]) % 12;
		}

		return false;
	}

	readonly property string black: "#000000"
	readonly property string red: "#ff0000"

	function colorNote(note, restore)
	{
		if (restore)
		{
			note.color = black;
		}
		else
		{
			if (isDiatonic(note, tonalCenter, mode))
			{
				note.color = black;
			}
			else
			{
				note.color = red;
			}
		}
	}

	property var diatonicDuration
	property var tonicDuration
	property var totalDuration

	function fitCount(note, tc, m)
	{
		var chord = note.parent;
		var t = chord.duration.numerator / chord.duration.denominator;
		if (isDiatonic(note, tc, m)) ++diatonicDuration;
		if (note.pitch % 12 == tc) ++tonicDuration;
		++totalDuration;
	}

	function fitScale()
	{
		var results = [];

		for (var tc = 0; tc < 12; ++tc)
		{
			for (var m = 0; m < 7; ++m)
			{
				diatonicDuration = 0;
				tonicDuration = 0;
				totalDuration = 0;
				applyToSelectedNotes(function (note) {fitCount(note, tc, m)});

				var x = {
					tonalCenter: tc,
					mode: m,
					tcName: toneNames[tc],
					mName: modeNames[m],
					diatonic: diatonicDuration / totalDuration * 100,
					tonic: tonicDuration / totalDuration * 100
				};
				results.push(x);
			}
		}

		results.sort(function (x, y) {
			var dDiff = y.diatonic - x.diatonic;
			var eps = 0.001;
			if (Math.abs(dDiff) < eps) return y.tonic - x.tonic;
			return dDiff;
		})

		resultsModel.clear();
		for (var i = 0; i < results.length; ++i)
		{
			resultsModel.append(results[i]);
		}
	}

	Column
	{
		padding: 12
		spacing: 12

		Grid
		{
			columns: 2
			spacing: 12

			Label
			{
				font.pointSize: 12
				text: "Tonal Center"
			}

			Label
			{
				font.pointSize: 12
				text: "Modus"
			}

			ComboBox
			{
				id: tonalBox
				model: toneNames
				currentIndex: tonalCenter
				onCurrentIndexChanged: tonalCenter = currentIndex
			}

			Binding
			{
				target: tonalBox
				property: "currentIndex"
				value: tonalCenter
			}

			ComboBox
			{
				id: modalBox
				model: modeNames
				currentIndex: mode
				onCurrentIndexChanged: mode = currentIndex
			}

			Binding
			{
				target: modalBox
				property: "currentIndex"
				value: mode
			}
		}

		Button
		{
			text: "Highlight Chromatic Notes"
			onClicked: applyToSelectedNotes(function (note) { colorNote(note, false); })
		}

		Button
		{
			text: "Remove Highlight"
			onClicked: applyToSelectedNotes(function (note) { colorNote(note, true); })
		}

		Button
		{
			text: "Find Best Fitting Scales"
			onClicked: fitScale()
		}

		ListModel
		{
			id: resultsModel
		}

		TableView
		{
			width: 300
			height: 450
			model: resultsModel

			onCurrentRowChanged: {
				if (currentRow >= 0)
				{
					var row = model.get(currentRow);
					tonalCenter = row.tonalCenter;
					mode = row.mode;
				}
			}

			TableViewColumn{ role: "tcName"; title: "Tonic"; width: 50 }
			TableViewColumn{ role: "mName"; title: "Mode"; width: 100 }
			TableViewColumn{ role: "diatonic"; title: "Diatonic%"; width: 75 }
			TableViewColumn{ role: "tonic"; title: "Tonic%"; width: 75 }
		}
	}
}
