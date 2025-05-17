## WriteSongInfoJSON
This module writes current song information to a json file: `Save/SongInfo.json`
The JSON is updated any time `ScreenGameplay` is entered, and can be used by anything you want!
Included is an example HTML file which can be used with OBS to create a clean on-screen display of the current song, a preview of this is below:

![Preview of the Browser Source](<Screenshot 2025-05-16 23-25-47.png>)

How to use this module, and the example browser source:
- Place `WriteSongInfoJSON.lua` in the `/Themes/Simply Love/Modules` folder.
- Place `Example-OBSBrowserSource.html` in the `/Save` folder.
- Add a Browser Source in OBS:
   - Check the Local File box.
   - Browse to and select the Example-OBSBrowserSource.html file.
   - Set the width to 760.
   - Set the height to 170.
- You can resize and move this source anywhere in the scene.

The JSON object output looks like this currently:
```
{
   "artist" : "Music Artist",
   "banner" : "/Songs/Pack/Song/Banner.ext",
   "blockRating" : 8,
   "diffColor" : [ 1, 0.49019607901573181, 0, 1 ],
   "difficulty" : "Expert",
   "length" : "2:06",
   "pack" : "Pack Name",
   "stepArtist" : "Step Artist",
   "stepCount" : 523,
   "stepDesc" : "DT",
   "style" : "single",
   "title" : "Song Title"
}
```