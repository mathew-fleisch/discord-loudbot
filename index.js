require('dotenv').config()
const Discord = require('discord.js')
const client = new Discord.Client()

let dblite = require('dblite')
let db = dblite(process.env.PATH_TO_SQLITE_DB || "/home/node/app/loudbot.sqlite")

db.query("CREATE TABLE IF NOT EXISTS loudbot (yells TEXT)")

client.on('ready', () => {
  console.log(`Logged in as ${client.user.tag}!`)
})
async function getRandomYell(db, msg) {
  db.query("SELECT * FROM loudbot ORDER BY RANDOM() LIMIT 1", async function(err, res) {
    if (err) {
      console.log("ERROR: ",err)
      return
    }
    console.log("getRandomYell( '" + res[0][0] + "' )")
    await msg.channel.send(res)
  })
}
client.on('message', async msg => {
  if (msg.channel.id != process.env.LOUDBOT_CHANNEL) {
    // console.log("Do not display in this channel: " + msg.channel.id + " != " + process.env.LOUDBOT_CHANNEL)
    return
  }
  if (msg.author.id == process.env.LOUDBOT_ID) {
    // console.log("Do not react to bot messages: " + msg.author.id + " == " + process.env.LOUDBOT_ID)
    return
  }
  // console.log("Not a bot message and in the restricted channel")
  if (!msg.content.match(/[a-z]/)) {
    console.log(msg.author.username + "( '" + msg.content + "' )")
    db.query("SELECT * FROM loudbot WHERE yells = ?", [msg.content], async function(err, res) {
      if (err) {
        console.log("ERROR: ",err)
        return
      }
      await getRandomYell(db, msg)
      if (res.length == 0) {
        db.query("INSERT INTO loudbot (yells) VALUES (?)", [msg.content])
        return
      }
    })
  }
})
client.login(process.env.DISCORD_TOKEN)