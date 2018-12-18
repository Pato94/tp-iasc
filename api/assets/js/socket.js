// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("queue:lobby", {})
// let chatInput = document.querySelector("#chat-input")
// let messagesContainer = document.querySelector("#messages")
let queuesContainer = document.querySelector("#queues-container")

function htmlToElement(html) {
  const template = document.createElement('template');
  html = html.trim(); // Never return a text node of whitespace as the result
  template.innerHTML = html;
  return template.content.firstChild;
}

// channel.on("new_msg", payload => {
//   let messageItem = document.createElement("li")
//   messageItem.innerText = `[${Date()}] ${payload.body}`
//   messagesContainer.appendChild(messageItem)
// })

const createQueue = (queueId, broadCast = false) => {
  const element = htmlToElement(`
    <div id="queue-${queueId}">
        <h2>Queue ${queueId} - Tipo ${broadCast? 'Broadcast' : 'WorkQueue'}</h2>
        <table>
        <tr>
        <td>
            <h2>Consumers</h2>
            <div id="consumers-${queueId}">
            </div>
            <button id="new-consumer-${queueId}">Click to add a consumer</button>
        </td>
        <td>
            <h2>Producers</h2>
            <div id="producers-${queueId}">
            </div>
            <button id="new-producer-${queueId}">Click to add a producer</button>
        </td>
        </tr>
        </table>
    </div>
  `)

  const createConsumer = (consumerId) => {
    // TODO: Setup socket connection

    const element = htmlToElement(`
      <div id="consumer-${queueId}-${consumerId}">
          <h3>Consumer</h3>
          <div id="consumer-messages-${queueId}-${consumerId}">
          </div>
      </div>
    `)

    let channel = socket.channel(`queue:${queueId}:consumer:${consumerId}`, {})
    let messagesContainer = element.querySelector(`#consumer-messages-${queueId}-${consumerId}`)

    channel.on("new_msg", payload => {
      let messageItem = document.createElement("li")
      messageItem.innerText = `${payload.body}`
      messagesContainer.appendChild(messageItem)
    })

    channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })

    return element
  }

  const createProducer = (producerId) => {
    // TODO: Setup socket connection
    const element = htmlToElement(`
      <div id="producer-${queueId}-${producerId}">
          <h3>Producer</h3>
          <div id="producer-messages-${queueId}-${producerId}">
          </div>
          <input id="chat-input-${queueId}-${producerId}" type="text"/>
      </div>
    `)

    let channel = socket.channel(`queue:${queueId}:producer:${producerId}`, {})
    let chatInput = element.querySelector(`#chat-input-${queueId}-${producerId}`)

    chatInput.addEventListener("keypress", event => {
      if(event.keyCode === 13){
        channel.push("new_msg", {queue_id: queueId, body: chatInput.value})
        chatInput.value = ""
      }
    })

    channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })

    return element
  }

  let nextConsumerId = 1
  let nextProducerId = 1

  const consumersContainer = element.querySelector(`#consumers-${queueId}`)
  const addConsumer = element.querySelector(`#new-consumer-${queueId}`)
  addConsumer.addEventListener("click", event => {
    const newConsumer = createConsumer(nextConsumerId)
    consumersContainer.appendChild(newConsumer)
    nextConsumerId++
  })

  const producersContainer = element.querySelector(`#producers-${queueId}`)
  const addProducer = element.querySelector(`#new-producer-${queueId}`)
  addProducer.addEventListener("click", event => {
    const newProducer = createProducer(nextProducerId)
    producersContainer.appendChild(newProducer)
    nextProducerId++
  })

  return element
}

// const createBroadcastQueue = (queueId) => {
//   const element = htmlToElement(`
//     <div id="queue-${queueId}">
//         <h2>Queue ${queueId} - Tipo Broadcast</h2>
//         <table>
//         <tr>
//         <td>
//             <h2>Consumers</h2>
//             <div id="consumers-${queueId}">
//             </div>
//             <button id="new-consumer-${queueId}">Click to add a consumer</button>
//         </td>
//         <td>
//             <h2>Producers</h2>
//             <div id="producers-${queueId}">
//             </div>
//             <button id="new-producer-${queueId}">Click to add a producer</button>
//         </td>
//         </tr>
//         </table>
//     </div>
//   `)
//
//   const createConsumer = (consumerId) => {
//     // TODO: Setup socket connection
//
//     const element = htmlToElement(`
//       <div id="consumer-${queueId}-${consumerId}">
//           <h3>Consumer</h3>
//           <div id="consumer-messages-${queueId}-${consumerId}">
//           </div>
//       </div>
//     `)
//
//     let channel = socket.channel(`queue:${queueId}:consumer:${consumerId}`, {})
//     let messagesContainer = element.querySelector(`#consumer-messages-${queueId}-${consumerId}`)
//
//     channel.on("new_msg", payload => {
//       let messageItem = document.createElement("li")
//       messageItem.innerText = `${payload.body}`
//       messagesContainer.appendChild(messageItem)
//     })
//
//     channel.join()
//       .receive("ok", resp => { console.log("Joined successfully", resp) })
//       .receive("error", resp => { console.log("Unable to join", resp) })
//
//     return element
//   }
//
//   const createProducer = (producerId) => {
//     // TODO: Setup socket connection
//     const element = htmlToElement(`
//       <div id="producer-${queueId}-${producerId}">
//           <h3>Producer</h3>
//           <div id="producer-messages-${queueId}-${producerId}">
//           </div>
//           <input id="chat-input-${queueId}-${producerId}" type="text"/>
//       </div>
//     `)
//
//     let channel = socket.channel(`queue:${queueId}:producer:${producerId}`, {})
//     let chatInput = element.querySelector(`#chat-input-${queueId}-${producerId}`)
//
//     chatInput.addEventListener("keypress", event => {
//       if(event.keyCode === 13){
//         channel.push("new_msg", {queue_id: queueId, body: chatInput.value})
//         chatInput.value = ""
//       }
//     })
//
//     channel.join()
//       .receive("ok", resp => { console.log("Joined successfully", resp) })
//       .receive("error", resp => { console.log("Unable to join", resp) })
//
//     return element
//   }
//
//   let nextConsumerId = 1
//   let nextProducerId = 1
//
//   const consumersContainer = element.querySelector(`#consumers-${queueId}`)
//   const addConsumer = element.querySelector(`#new-consumer-${queueId}`)
//   addConsumer.addEventListener("click", event => {
//     const newConsumer = createConsumer(nextConsumerId)
//     consumersContainer.appendChild(newConsumer)
//     nextConsumerId++
//   })
//
//   const producersContainer = element.querySelector(`#producers-${queueId}`)
//   const addProducer = element.querySelector(`#new-producer-${queueId}`)
//   addProducer.addEventListener("click", event => {
//     const newProducer = createProducer(nextProducerId)
//     producersContainer.appendChild(newProducer)
//     nextProducerId++
//   })
//
//   return element
// }

const addWorkQueue = document.querySelector("#new-worker-queue")
let nextQueueId = 1
addWorkQueue.addEventListener("click", event => {
  channel.push("new_queue", {queue_id: nextQueueId, broadcast: false})
  queuesContainer.appendChild(createQueue(nextQueueId, false))
  nextQueueId++
})

const addBroadcastQueue = document.querySelector("#new-broadcast-queue")
addBroadcastQueue.addEventListener("click", event => {
  channel.push("new_queue", {queue_id: nextQueueId, broadcast: true})
  queuesContainer.appendChild(createQueue(nextQueueId, true))
  nextQueueId++
})

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket