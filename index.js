require('dotenv').config()
const Discord = require('discord.js')
const client = new Discord.Client()

let dblite = require('dblite')
let db = dblite(process.env.PATH_TO_SQLITE_DB)

db.query("CREATE TABLE IF NOT EXISTS loudbot (yells TEXT)")

client.on('ready', () => {
  console.log(`Logged in as ${client.user.tag}!`)
})
async function getRandomYell(db, msg) {
  console.log("getRandomYell()")
  db.query("SELECT * FROM loudbot ORDER BY RANDOM() LIMIT 1", async function(err, res) {
    if (err) {
      console.log("ERROR: ",err)
      return
    }
    await msg.channel.send(res)
  })
}
client.on('message', async msg => {
  // console.log(msg)
  if (msg.channel.id != process.env.RESTRICT_CHANNEL) {
    console.log("Do not display in this channel: " + msg.channel.id + " != " + process.env.RESTRICT_CHANNEL)
    return
  }
  if (msg.author.id == process.env.EXCLUDE_BOT) {
    console.log("Do not react to bot messages: " + msg.author.id + " == " + process.env.EXCLUDE_BOT)
    return
  }
  // console.log("Not a bot message and in the restricted channel")
  if (!msg.content.match(/[a-z]/)) {
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