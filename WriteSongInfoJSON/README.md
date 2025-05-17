## WriteSongInfoJSON
This module writes current song information to a json file: `Save/SongInfo.json`
The JSON is updated any time `ScreenGameplay` is entered, and can be used by anything you want!
Included is an example HTML file which can be used with OBS to create a clean on-screen display of the current song, a preview of this is below:

![Preview of the Browser Source](<Screenshot 2025-05-16 23-25-47.png>)

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