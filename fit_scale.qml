// Based on Musescore Colornotes Hooktheory Plugin

import QtQuick 2.6
import QtQuick.Controls 2.2
import MuseScore 3.0
import QtQuick.Window 2.2


MuseScore
{
    version: "1.0"
	menuPath: "Plugins.Fit Scale"
	pluginType: "dock"

	readonly property string black: "#000000"
	readonly property string red: "#ff0000"
	readonly property var ionian: [2, 2, 1, 2, 2, 2, 1]

	property var tonalCenter: tonalBox.currentIndex
	property var mode: modalBox.currentIndex

	function applyToSelectedNotes(func, restore)
	{
		if (!curScore) return;

		var fullScore = !(curScore.selection.elements.length > 1);
		if (fullScore)
		{
			cmd("select-all");
			curScore.startCmd();
		}

		for (var i in curScore.selection.elements)
		{
			var note = curScore.selection.elements[i];
			if (note.pitch)
			{
				func(note, restore);
			}
		}

		if (fullScore)
		{
			curScore.endCmd();
			cmd("escape");
		}
	}

	function colorNote(note, restore)
	{
		if (restore)
		{
			note.color = black;
		}
		else
		{
			var diatonic = false;
			for (var i = 0, pitch = tonalCenter; i < 7; ++i)
			{
				if (note.pitch % 12 == pitch)
				{
					diatonic = true;
					break;
				}
				pitch = (pitch + ionian[(mode + i) % 7]) % 12;
			}

			if (diatonic)
			{
				note.color = black;
			}
			else
			{
				note.color = red;
			}
		}
	}

	Grid
	{
		columns: 2
		padding: 12
		spacing: 12

		Label
		{
			font.pointSize: 12
			text: "Tonal Center"
		}

		ComboBox
		{
			id: tonalBox
			model: ["C", "C#/Db", "D", "D#/Eb", "E", "F", "F#/Gb", "G", "G#/Ab", "A", "A#/Bb", "B"]
		}

		Label
		{
			font.pointSize: 12
			text: "Modus"
		}

		ComboBox
		{
			id: modalBox
			model: ["Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Locrian"]
		}

		Button
		{
			text: "Highlight Chromatic Notes"
			onClicked: applyToSelectedNotes(colorNote, false)
		}

		Button
		{
			text: "Remove Highlight"
			onClicked: applyToSelectedNotes(colorNote, true)
		}
	}
}
