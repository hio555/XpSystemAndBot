
require('dotenv').config({ path: '.env' })
const rbx = require("noblox.js");
const express = require("express");
const app = express();
const Discord = require("discord.js")


/*
*****************************************
           IMPORTANT!!!!!
*****************************************

When changing environment values, update them in the .env file (so it works locally)

If deploying on fly.io, run the following command (assuming flyctl is installed: https://fly.io/docs/flyctl/install/)

flyctl secrets set VAR=VALUE

where VAR is the name of the variable in the .env file and VALUE is the value of that variable

e.g. flyctl secrets set ROBLOX=abcdefg 

You will need to update the roblox bot cookie if the bot account gets logged out


*/
const discordToken = process.env.DISCORD;
const robloxCookie = process.env.ROBLOX;
const authTokenString = process.env.AUTH_TOKEN;
const groupId = 35535718


let discordBot = null


const port = process.env.PORT;


app.set('port', port);
app.use(express.json());
app.use(express.urlencoded({ extended: true }))


async function startApp() {
    await rbx.setCookie(robloxCookie);
    let currentUser = await rbx.getCurrentUser();
    console.log("Bot logged in as: " + currentUser.UserName);

    discordBot = new Discord.Client({
        intents: ['Guilds', 'GuildMessages']
    })

    discordBot.login(discordToken)

}


startApp();


app.post("/updaterank", (req, res) => {
    var authToken = req.headers['authorization'];

    if (!authToken || authToken !== authTokenString) {
        res.status(403).json({ message: "Unauthorized" });
        return
    }

    var Uid = req.body.uid;
    var Rank = req.body.rank;


    rbx.setRank(groupId, Uid, Rank);
    res.json(`Ranked! " + ${groupId} + ${Uid} + ${Rank}`);
    console.log(`Ranked! " + ${groupId} + ${Uid} + ${Rank}`)
});


app.post("/logexp", async (req, res) => {
    var authToken = req.headers['authorization'];


    if (!authToken || authToken !== authTokenString) {
        return res.status(403).json({ message: "Unauthorized" });
    }

    var Staff = req.body.staff;
    var Amount = req.body.amount;
    var Recipient = req.body.recipient;
    var TotalExp = req.body.totalExp;

    var message = `${Staff} has given ${Recipient} **${Amount}** EXP, TOTAL PLAYER EXP: **${TotalExp}**`

    try {
        // Ensure client is logged in and ready before trying to access the channel
        const channel = await discordBot.channels.fetch("1337529578771579011");
        await channel.send(message); // Send the message to the channel
        return res.json({ message: "Success!" })
    } catch (error) {
        return res.status(500).json({ message: "Error sending message.", error: error.message });
    }

})

const listener = app.listen(port, () => {
    console.log("Your app is listening on port " + listener.address().port);
});

console.log("Setup success!")
