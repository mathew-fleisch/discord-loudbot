require('dotenv').config();
const Discord = require('discord.js');
const client = new Discord.Client();

let dblite = require('dblite');
let db = dblite(process.env.PATH_TO_SQLITE_DB);

db.query("CREATE TABLE IF NOT EXISTS loudbot (yells TEXT)");

client.on('ready', () => {
  console.log(`Logged in as ${client.user.tag}!`);
});

client.on('message', msg => {
  if (msg.channel.id == process.env.RESTRICT_CHANNEL && msg.author.id != process.env.EXCLUDE_BOT) {
    if (!msg.content.match(/[a-z]/)) {
      // TODO: exclude duplicates
      db.query("INSERT INTO loudbot (yells) VALUES (?)", [msg.content]);
      db.query("SELECT * FROM loudbot ORDER BY RANDOM() LIMIT 1", function(err, res) {
         if (err) {
           console.log("ERROR:",err);
           return;
         }
         msg.channel.send(res);
      });
    }
  }
});
client.login(process.env.DISCORD_TOKEN);


