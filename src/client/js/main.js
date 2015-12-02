;(function() {

  var BLOCK_SIZE = 10;

  var Game = function() {
    var screen = document.getElementById("screen").getContext('2d');

    this.socket = new WebSocket('ws://localhost:4567');
    this.dataReceived = null;

    var keyhandler = new Keyboarder(this.socket);

    var self = this;
    this.socket.onopen = function() {
        this.isopen = true;
        console.log("Connected!");
    }

    this.socket.onmessage = function(e) {
      if (typeof e.data == "string") {
          self.dataReceived = JSON.parse(e.data);
          console.log(self.dataReceived);
      }
    }

    this.socket.onclose = function(e) {
        console.log("Connection closed.");
        this.socket = null;
        this.isopen = false;
    }

    this.socket.sendMessage = function(data, type) {
      if (this.isopen) {
          switch(type) {
              case 'json':
                  this.send(JSON.stringify(data));
                  break;
              case 'string':
                  this.send(data);
                  break;
          }
      } else {
          console.log("Connection not opened.")
      }
    }
  };

  Game.prototype = {
    draw: function(screen) {
      screen.clearRect(0, 0, this.size.x, this.size.y);

      // Draw based on JSON from server
    }
  };


  var Keyboarder = function(socket) {
    var keyState = {};

    window.addEventListener('keydown', function(e) {
      keyState[e.keyCode] = true;
      socket.sendMessage(e.keyCode, "json");
      // console.log("key pressed!")
    });

    window.addEventListener('keyup', function(e) {
      keyState[e.keyCode] = false;
    });

    this.isDown = function(keyCode) {
      return keyState[keyCode] === true;
    };

    this.KEYS = { LEFT: 37, RIGHT: 39, UP: 38, DOWN: 40 };
  };


  var drawRect = function(screen, body, color) {
    screen.fillStyle = color;
    screen.fillRect(body.center.x - body.size.x / 2, body.center.y - body.size.y / 2,
                    body.size.x, body.size.y);
  };

  window.addEventListener('load', function() {
    new Game();
  });
})(this);
