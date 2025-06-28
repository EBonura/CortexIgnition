# GameState.gd
extends Node

enum GameMode { MENU, PLAYING, PAUSED }
var current_mode = GameMode.MENU
