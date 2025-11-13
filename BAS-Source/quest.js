// ================================================================
// QUEST ADVENTURE GAME - JavaScript Version
// ================================================================
// Converted from QBasic 4.5 to modern JavaScript
// A text-based adventure game with rooms, artifacts, and creatures
// ================================================================

class QuestGame {
  constructor() {
    // Game state variables
    this.currentRoom = 0;
    this.homeRoom = 0;
    this.warehouseRoom = 0;
    this.darkRoom = 0;
    this.moveCount = 100;
    this.carryCount = 0;
    this.playerState = 0;
    this.score = 0;
    this.penaltyPoints = 0;
    this.randomSeed = 1;

    // Game arrays
    this.artifactLocation = new Array(61).fill(0);
    this.artifactRecord = new Array(61).fill(0);
    this.gremlinLocation = new Array(41).fill(0);
    this.gremlinRecord = new Array(41).fill(0);
    this.gremlinFactor = new Array(41).fill(0);
    this.locationList = new Array(6).fill(0);
    this.recentPlaces = new Array(6).fill(0);

    // Game control variables
    this.numArtifacts = 0;
    this.numGremlins = 0;
    this.currentRecord = 0;
    this.flagRecord = 0;
    this.actionResult = "Y";
    this.secondaryAction = "0";
    this.recordContent = "";
    this.placeRecord = "";

    // Text processing variables
    this.word1 = "";
    this.word2 = "";
    this.curCommand = "";
    this.action = "";
    this.outputBuffer = "";
    this.textOutput = "";
    this.commandArgs = "";
    this.gremlinData = "";
    this.targetGremlin = 0;
    this.foundTarget = 0;
    this.newPlace = 0;
    this.parsedNumber = 0;
    this.optimalMove = 0;
    this.parsedText1 = "";
    this.parsedText2 = "";
    this.textContinue = "";

    // Data storage (would be loaded from file)
    this.dataRecords = [];
    
    // Output callback
    this.onOutput = null;
    this.onInput = null;
  }

  // ================================================================
  // INITIALIZATION
  // ================================================================
  
  initializeGame() {
    this.randomSeed = 1;
    this.carryCount = 0;
    this.secondaryAction = "0";
    this.moveCount = 100;
    this.penaltyPoints = 0;
    this.actionResult = "N";
    this.outputBuffer = "";
  }

  loadGameData() {
    this.currentRecord = 0;
    this.getRecord();

    this.currentRoom = parseInt(this.recordContent.substr(20, 4));
    this.homeRoom = parseInt(this.recordContent.substr(24, 4));
    this.warehouseRoom = parseInt(this.recordContent.substr(28, 4));
    this.darkRoom = parseInt(this.recordContent.substr(32, 4));
    this.currentRecord = parseInt(this.recordContent.substr(10, 4));
    this.flagRecord = parseInt(this.recordContent.substr(16, 4));
    this.numArtifacts = parseInt(this.recordContent.substr(8, 2));
    this.numGremlins = parseInt(this.recordContent.substr(14, 2));

    this.loadArtifacts();
    this.loadGremlins();
  }

  loadArtifacts() {
    this.currentRecord = this.flagRecord;
    do {
      this.getRecord();
      const idx = parseInt(this.recordContent.substr(90, 2));
      if (idx >= 1 && idx <= 60) {
        this.artifactLocation[idx] = parseInt(this.recordContent.substr(92, 4));
        this.artifactRecord[idx] = this.currentRecord;
      }
      this.currentRecord = parseInt(this.recordContent.substr(0, 4));
    } while (this.currentRecord > 0);
  }

  loadGremlins() {
    this.currentRecord = this.flagRecord;
    do {
      this.getRecord();
      const idx = parseInt(this.recordContent.substr(90, 2));
      if (idx >= 1 && idx <= 40) {
        this.gremlinLocation[idx] = parseInt(this.recordContent.substr(92, 4));
        this.gremlinRecord[idx] = this.currentRecord;
        this.gremlinFactor[idx] = parseInt(this.recordContent.substr(80, 1));
      }
      this.currentRecord = parseInt(this.recordContent.substr(0, 4));
    } while (this.currentRecord > 0);
  }

  validateGameState() {
    for (let i = 1; i <= this.numArtifacts; i++) {
      if (this.artifactLocation[i] < -1) {
        this.artifactLocation[i] = this.currentRoom;
      }
    }
    
    for (let i = 1; i <= this.numGremlins; i++) {
      if (this.gremlinLocation[i] < -1) {
        this.gremlinLocation[i] = -1;
      }
    }
    
    if (this.carryCount < 0) this.carryCount = 0;
    if (this.carryCount > this.numArtifacts) this.carryCount = this.numArtifacts;
  }

  // ================================================================
  // MAIN GAME LOOP
  // ================================================================

  async startGameLoop() {
    this.actionResult = "N";
    
    while (true) {
      if (this.actionResult === "Y") {
        this.processMovement();
      } else {
        this.processGremlins();
      }

      this.arriveAtLocation();

      if (this.actionResult !== "Y") {
        this.checkGremlinAttacks();
      }

      this.processLocationDescription();
      
      // Wait for player input
      const input = await this.getPlayerInput();
      if (input === null) break; // Exit condition
      
      this.parseCommand(input);
      this.processCommand();
    }
  }

  // ================================================================
  // MOVEMENT AND LOCATION
  // ================================================================

  processMovement() {
    this.actionResult = "Y";
    let tempString = "The";
    let followString = "X";

    for (let i = 1; i <= this.numGremlins; i++) {
      if (this.gremlinLocation[i] === this.currentRoom) {
        this.currentRecord = this.gremlinRecord[i];
        this.getRecord();

        const stateValue = parseInt(this.recordContent.substr(8, 1));

        if (parseInt(this.recordContent.substr(79 + 2 * stateValue, 1)) > Math.random() * 9) {
          this.textOutput = tempString;
          this.processTextOutput();

          if (tempString === "The") {
            followString = "%4has";
          } else {
            followString = "%4have";
          }

          tempString = "%4and";
          this.processDescription();

          this.gremlinLocation[i] = -this.newPlace;
        }
      }
    }

    this.currentRoom = this.newPlace;

    if (followString !== "X") {
      this.textOutput = followString + " following you. ";
      this.processTextOutput();
      this.actionResult = "N";
    }
  }

  arriveAtLocation() {
    this.currentRecord = this.currentRoom;
    this.getRecord();
    this.placeRecord = this.recordContent;
    this.currentRecord = parseInt(this.placeRecord.substr(0, 4));

    // Update location history
    for (let i = 1; i <= 4; i++) {
      this.recentPlaces[i] = this.recentPlaces[i + 1];
    }
    this.recentPlaces[5] = this.currentRoom;

    this.processLocationDescription();

    this.playerState = parseInt(this.placeRecord.substr(8, 1));
    this.currentRecord = parseInt(this.placeRecord.substr(5 + 4 * this.playerState, 4));
    this.processLocationDescription();

    this.processArtifactsAtLocation();
    this.processGremlinsAtLocation();
  }

  // ================================================================
  // COMMAND PROCESSING
  // ================================================================

  async getPlayerInput() {
    this.flushOutput();
    this.calculateScore();

    this.output(this.score + "  :");
    
    if (this.onInput) {
      return await this.onInput();
    }
    return null;
  }

  parseCommand(inputString) {
    let result = this.extractWord(inputString);
    this.word1 = result.word;
    inputString = result.remaining;
    
    if (this.word1.length === 0) {
      this.word1 = "*   ";
    } else {
      this.word1 = (this.word1 + "   ").substr(0, 4);
    }

    result = this.extractWord(inputString);
    this.word2 = result.word;
    
    if (this.word2.length === 0) {
      this.word2 = "*   ";
    } else {
      this.word2 = (this.word2 + "   ").substr(0, 4);
    }

    this.word1 = this.convertToUppercase(this.word1);
    this.word2 = this.convertToUppercase(this.word2);

    this.randomSeed = inputString.length;
    this.moveCount++;
  }

  processCommand() {
    this.curCommand = "?";
    this.action = "?";

    this.checkMovementCommands();
    if (this.curCommand !== "?") {
      this.handleMovement();
      return;
    }

    this.checkKeywordInteractions();
    if (this.action !== "?") {
      this.executeAction();
      return;
    }

    this.checkStandardCommands();
    if (this.action !== "?") {
      this.executeAction();
      return;
    }

    this.currentRecord = 344;
    this.displayMessage();
  }

  // ================================================================
  // TEXT PROCESSING
  // ================================================================

  extractWord(inputString) {
    // Remove leading spaces
    while (inputString.length > 0 && inputString[0] === " ") {
      inputString = inputString.substr(1);
    }

    // Find next space
    let spacePos = inputString.indexOf(" ");
    if (spacePos === -1) spacePos = inputString.length;

    const word = spacePos > 0 ? inputString.substr(0, spacePos) : "";
    const remaining = spacePos < inputString.length ? inputString.substr(spacePos + 1) : "";

    return { word, remaining };
  }

  convertToUppercase(str) {
    return str.toUpperCase();
  }

  processTextOutput() {
    if (this.textOutput.length === 0) return;

    if (this.textOutput[this.textOutput.length - 1] === ".") {
      this.textOutput += " ";
    }

    let remaining = this.textOutput;

    while (remaining.length > 0) {
      const percentPos = remaining.indexOf("%");
      const endPos = percentPos === -1 ? remaining.length : percentPos;

      this.outputBuffer += remaining.substr(0, endPos) + " ";
      if (this.outputBuffer.length > 70) this.wrapText();

      if (percentPos === -1 || percentPos >= remaining.length - 1) break;

      const codeChar = remaining[percentPos + 1];
      const codeVal = parseInt(codeChar);

      switch (codeVal) {
        case 1:
          this.flushOutput();
          break;
        case 2:
          this.outputBuffer += "%";
          break;
        case 3:
          if (this.outputBuffer.length > 0) {
            this.outputBuffer = this.outputBuffer.substr(0, this.outputBuffer.length - 1);
          }
          break;
        case 4:
          if (this.outputBuffer.length >= 4) {
            this.outputBuffer = this.outputBuffer.substr(0, this.outputBuffer.length - 4) + " ";
          }
          break;
      }

      remaining = remaining.substr(percentPos + 2);
    }
  }

  wrapText() {
    let wrapPos = this.outputBuffer.lastIndexOf(" ", 60);
    if (wrapPos === -1) wrapPos = this.outputBuffer.length;

    this.output(this.outputBuffer.substr(0, wrapPos));
    this.outputBuffer = this.outputBuffer.substr(wrapPos);

    while (this.outputBuffer.length > 0 && this.outputBuffer[0] === " ") {
      this.outputBuffer = this.outputBuffer.substr(1);
    }
  }

  flushOutput() {
    if (this.outputBuffer.length > 0) this.wrapText();
    if (this.outputBuffer.length > 0) {
      this.output(this.outputBuffer);
      this.outputBuffer = "";
    }
  }

  output(text) {
    if (this.onOutput) {
      this.onOutput(text);
    } else {
      console.log(text);
    }
  }

  // ================================================================
  // GAME UTILITIES
  // ================================================================

  getRecord() {
    const recordNumber = this.currentRecord;
    if (recordNumber < 0 || recordNumber >= this.dataRecords.length) {
      this.recordContent = "";
      return;
    }
    this.recordContent = this.dataRecords[recordNumber] || "";
  }

  saveRecord() {
    if (this.currentRecord >= 0 && this.currentRecord < this.dataRecords.length) {
      this.dataRecords[this.currentRecord] = this.recordContent;
    }
  }

  displayMessage() {
    if (this.currentRecord === 0) return;

    this.getRecord();
    this.parseTextTokens();

    this.textOutput = this.parsedText1;
    this.processTextOutput();

    if (this.textContinue === "1") return;

    this.textOutput = this.parsedText2;
    this.processTextOutput();

    if (this.textContinue === "3") {
      this.currentRecord++;
      this.displayMessage();
    }
  }

  parseTextTokens() {
    this.parsedText1 = this.recordContent.substr(0, 40);
    this.parsedText2 = this.recordContent.substr(40, 40);
    this.textContinue = this.recordContent[this.recordContent.length - 1] === "3" ? "3" : "1";
  }

  calculateScore() {
    this.score = 0;

    for (let i = 1; i <= this.numArtifacts; i++) {
      if (this.artifactLocation[i] !== this.homeRoom) continue;

      this.currentRecord = this.artifactRecord[i];
      this.getRecord();
      const stateValue = parseInt(this.recordContent.substr(8, 1));
      if (this.recordContent.substr(79 + stateValue * 2, 1) === "2") {
        this.score += parseInt(this.recordContent.substr(78, 3));
      }
    }

    if (this.moveCount === 0) this.moveCount = 1;
    this.score = Math.floor(1000 * (10 * this.score - this.penaltyPoints) / this.moveCount) / 100;
  }

  // ================================================================
  // MOVEMENT COMMANDS
  // ================================================================

  checkMovementCommands() {
    const directionString = "NORTSOUTEASTWESTUP  DOWN" + this.placeRecord.substr(25, 8);

    for (let idx = 0; idx < directionString.length; idx += 4) {
      if (this.word1 === directionString.substr(idx, 4)) {
        const cmdCode = Math.floor((idx + 4) / 4);
        this.curCommand = "C" + String(cmdCode).padStart(2, "0");
        break;
      }
    }
  }

  handleMovement() {
    this.action = "?";
    this.recordContent = this.placeRecord;
    this.findActionInRecord();

    if (this.action !== "?") {
      this.executeAction();
    } else {
      this.currentRecord = 343;
      this.displayMessage();
    }
  }

  // ================================================================
  // STANDARD COMMANDS
  // ================================================================

  checkStandardCommands() {
    const commands = ["LOOK", "INVE", "FEED", "SCOR", "END ", "ATTA", "KILL"];
    let commandIndex = 0;

    for (let i = 0; i < commands.length; i++) {
      if (this.word1 === commands[i]) {
        commandIndex = i + 1;
        break;
      }
    }

    switch (commandIndex) {
      case 1: this.handleLookCommand(); break;
      case 2: this.handleInventoryCommand(); break;
      case 3: this.handleFeedCommand(); break;
      case 4: this.handleScoreCommand(); break;
      case 5: this.handleEndCommand(); break;
      case 6: this.handleAttackCommand(); break;
      case 7: this.handleKillCommand(); break;
      default: this.checkArtifactCommands(); break;
    }
  }

  handleLookCommand() {
    this.currentRecord = parseInt(this.placeRecord.substr(0, 4));
    this.displayMessage();
  }

  handleInventoryCommand() {
    this.currentRecord = 342;
    this.displayMessage();

    let anyItem = false;

    for (let i = 1; i <= this.numArtifacts; i++) {
      if (this.artifactLocation[i] === 0) {
        this.textOutput = "%1A ";
        this.processTextOutput();
        this.currentRecord = this.artifactRecord[i];
        this.getRecord();
        this.processDescription();
        anyItem = true;
      }
    }

    if (!anyItem) {
      this.textOutput = "%1NOTHING%1";
      this.processTextOutput();
    }
  }

  handleFeedCommand() {
    this.word1 = "F   ";
    this.handleCreatureInteraction();
  }

  handleAttackCommand() {
    this.word1 = "A   ";
    this.handleCreatureInteraction();
  }

  handleKillCommand() {
    this.word1 = "K   ";
    this.handleCreatureInteraction();
  }

  handleScoreCommand() {
    this.flushOutput();
    this.output("SCORE: " + this.score);
  }

  handleEndCommand() {
    this.flushOutput();
    this.output("SCORE: " + this.score);
    // End game
  }

  handleCreatureInteraction() {
    let targetGremlin = 0;
    
    for (let i = 1; i <= this.numGremlins; i++) {
      if (this.gremlinLocation[i] === this.currentRoom) {
        this.currentRecord = this.gremlinRecord[i];
        this.getRecord();

        if (this.word2 === this.recordContent.substr(25, 4) || 
            this.word2 === this.recordContent.substr(29, 4)) {
          targetGremlin = i;
          break;
        }
      }
    }

    if (targetGremlin === 0) {
      this.currentRecord = 339;
      this.displayMessage();
      return;
    }

    this.curCommand = this.word1[0] + String(Math.floor(targetGremlin * 4 / 100)).padStart(2, "0");
    this.gremlinData = this.recordContent;
    this.targetGremlin = targetGremlin;

    this.executeAction();
  }

  // ================================================================
  // ACTION EXECUTION
  // ================================================================

  executeAction() {
    const actionType = parseInt(this.action[0]) + 1;

    switch (actionType) {
      case 1: return;
      case 2: this.executeMessageAction(); break;
      case 3: this.executeMoveAction(); break;
      case 4: this.executeComplexAction(); break;
      case 5: this.executeCarryAction(); break;
      case 6: this.executeDropAction(); break;
      case 7: this.executePlayerAction(); break;
      case 8: this.executeStateAction(); break;
      case 9: this.executeDestroyAction(); break;
      case 10: this.executeComplexAction(); break;
    }

    if (this.secondaryAction !== "0") {
      this.action = this.secondaryAction;
      this.secondaryAction = "0";
      this.executeAction();
    }
  }

  executeMessageAction() {
    const messageNumber = this.action.substr(1, 4);
    this.currentRecord = parseInt(messageNumber);
    this.displayMessage();
  }

  executeMoveAction() {
    this.newPlace = parseInt(this.action.substr(this.action.length - 4));
    this.currentRecord = this.newPlace;
    this.getRecord();

    const lastChar = this.recordContent[this.recordContent.length - 1];
    if (lastChar < "6") {
      this.processMovement();
    } else if (lastChar > "6") {
      this.processComplexMovement();
    } else {
      this.processConditionalMovement();
    }
  }

  executeCarryAction() {
    this.secondaryAction = "0";
  }

  executeDropAction() {
    if (this.action.substr(2, 1) === "1") {
      if (this.artifactLocation[this.foundTarget] === 0) {
        this.carryCount--;
      }
      this.placeArtifact(this.foundTarget);
      this.currentRecord = 346;
      this.displayMessage();
    }
    
    this.action = this.secondaryAction;
    this.secondaryAction = "0";
    if (this.action !== "0") this.executeAction();
  }

  executePlayerAction() {
    const actionChar = this.action[0];
    
    if (actionChar === "4") {
      this.handlePlayerDeath();
    } else if (actionChar === "5") {
      this.handlePlayerStateChange();
    } else if (actionChar === "6") {
      this.handlePlayerMovement();
    } else if (actionChar === "7") {
      this.handlePlayerCommand();
    } else if (actionChar === "8") {
      this.handlePlayerStateToggle();
    }
  }

  executeStateAction() {
    this.currentRecord = parseInt(this.action.substr(this.action.length - 4));
    this.getRecord();
    
    const currentState = parseInt(this.recordContent.substr(8, 1));
    
    if (currentState === 1) {
      this.recordContent = this.recordContent.substr(0, 8) + "2" + this.recordContent.substr(9);
    } else {
      this.recordContent = this.recordContent.substr(0, 8) + "1" + this.recordContent.substr(9);
    }
    
    this.saveRecord();
    
    this.currentRecord = parseInt(this.recordContent.substr(13 + 4 * parseInt(this.recordContent.substr(8, 1)), 4));
    this.displayMessage();
    
    this.action = this.secondaryAction;
    this.secondaryAction = "0";
    if (this.action !== "0") this.executeAction();
  }

  executeDestroyAction() {
    if (this.action[0] === "9") {
      this.destroyObject();
    } else {
      this.textOutput = "A ";
      this.processTextOutput();
      this.processArtifactDescription();
      this.processDescription();
      this.currentRecord = 348;
      this.displayMessage();
      this.destroyObject();
    }
    
    this.action = this.secondaryAction;
    this.secondaryAction = "0";
    if (this.action !== "0") this.executeAction();
  }

  executeComplexAction() {
    const operationType = this.action.substr(2, 1);
    
    if (this.action.substr(this.action.length - 2) === "??") {
      this.action = this.action.substr(0, 3) + this.commandArgs;
    }

    if (operationType === "0") {
      this.currentRecord = this.currentRoom;
      this.processTargetAction();
      return;
    }

    const targetIndex = parseInt(this.action.substr(this.action.length - 2));

    if (targetIndex > 0) {
      this.processSpecificTarget(targetIndex, operationType);
    } else {
      this.processAllTargets(operationType);
    }
  }

  // ================================================================
  // GREMLINS AND CREATURES
  // ================================================================

  processGremlins() {
    let targetGremlin = 0;

    for (let i = 1; i <= this.numGremlins; i++) {
      if (this.gremlinLocation[i] === this.currentRoom) {
        this.gremlinFactor[i]++;
        if (Math.random() * 10 <= this.gremlinFactor[i]) {
          targetGremlin = i;
          this.gremlinFactor[i] = 9;
          break;
        }
      }
    }

    if (targetGremlin > 0) {
      this.processGremlinAction(targetGremlin);
    }
  }

  processGremlinAction(gIndex) {
    this.currentRecord = this.gremlinRecord[gIndex];
    this.getRecord();

    this.gremlinFactor[gIndex] = parseInt(this.recordContent.substr(85, 1));
    const stateValue = parseInt(this.recordContent.substr(8, 1));
    this.currentRecord = parseInt(this.recordContent.substr(86, 4));
    
    if (this.currentRecord === 0) return;

    const successChance = parseInt(this.recordContent.substr(80 + 2 * stateValue, 1));
    this.getRecord();
    this.actionResult = "Y";

    if (Math.random() * 9 < successChance) {
      this.processSuccessfulCondition();
    } else {
      this.processFailedCondition();
    }
  }

  checkGremlinAttacks() {
    for (let i = 1; i <= this.numGremlins; i++) {
      if (this.gremlinLocation[i] === this.currentRoom) {
        this.currentRecord = this.gremlinRecord[i];
        this.processObjectInteraction();
      }

      if (this.gremlinLocation[i] === -this.currentRoom) {
        this.gremlinLocation[i] = this.currentRoom;
      }
    }
  }

  // ================================================================
  // OBJECTS AND INTERACTIONS
  // ================================================================

  processArtifactsAtLocation() {
    this.optimalMove = 9999;

    for (let i = 1; i <= this.numArtifacts; i++) {
      if (this.artifactLocation[i] === this.currentRoom || this.artifactLocation[i] === 0) {
        this.currentRecord = this.artifactRecord[i];
        this.processObjectInteraction();
      }
    }
  }

  processGremlinsAtLocation() {
    for (let i = 1; i <= this.numGremlins; i++) {
      if (this.gremlinLocation[i] === this.currentRoom) {
        this.currentRecord = this.gremlinRecord[i];
        this.processObjectInteraction();
      }
    }
  }

  processObjectInteraction() {
    this.getRecord();
    const nameRecord = parseInt(this.recordContent.substr(5 + 4 * parseInt(this.recordContent.substr(8, 1)), 4));
    this.currentRecord = parseInt(this.recordContent.substr(4, 4));

    if (this.currentRecord === 0) {
      this.optimalMove = this.currentRecord;
      this.currentRecord = nameRecord;
      this.displayMessage();
      return;
    }

    if (this.currentRecord === this.optimalMove) {
      this.textOutput = "%4and a";
      this.processTextOutput();
    } else {
      this.displayMessage();
    }

    this.optimalMove = this.currentRecord;
    this.currentRecord = nameRecord;
    this.displayMessage();
  }

  processDescription() {
    const stateValue = parseInt(this.recordContent.substr(8, 1));
    this.currentRecord = parseInt(this.recordContent.substr(5 + 4 * stateValue, 4));
    this.displayMessage();
  }

  processArtifactDescription() {
    this.currentRecord = parseInt(this.recordContent.substr(5 + 4 * parseInt(this.recordContent.substr(8, 1)), 4));
  }

  // ================================================================
  // ARTIFACT COMMANDS
  // ================================================================

  checkArtifactCommands() {
    for (let i = 1; i <= this.numArtifacts; i++) {
      if (this.artifactLocation[i] === this.currentRoom || this.artifactLocation[i] === 0) {
        this.currentRecord = this.artifactRecord[i];
        this.getRecord();

        if (this.recordContent.substr(25, 4) === "* KR") {
          this.currentRecord = parseInt(this.recordContent.substr(29, 4));
          this.findActionInRecord();
          if (this.action !== "?") {
            this.handleArtifactAction(i);
            return;
          }
        }

        if (this.recordContent.substr(25, 4) === this.word2 || 
            this.recordContent.substr(29, 4) === this.word2) {
          this.handleSpecificArtifact(i);
          return;
        }
      }
    }

    this.currentRecord = this.darkRoom;
    this.findActionInRecord();
  }

  handleArtifactAction(artifactIndex) {
    if (this.word1 === "CARR") {
      this.handleCarryArtifact(artifactIndex);
    } else if (this.word1 === "DROP") {
      this.handleDropArtifact(artifactIndex);
    } else if (this.word1 === "THRO") {
      this.handleThrowArtifact(artifactIndex);
    } else {
      this.handleUseArtifact(artifactIndex);
    }
  }

  handleSpecificArtifact(artifactIndex) {
    if (this.word1 === "CARR") {
      this.handleCarryArtifact(artifactIndex);
      return;
    }

    if (this.word1 === "DROP" || this.word1 === "THRO") {
      if (this.artifactLocation[artifactIndex] !== 0) {
        this.currentRecord = 339;
        this.displayMessage();
        return;
      }

      this.carryCount--;
      this.placeArtifact(artifactIndex);

      if (this.word1 === "DROP") {
        return;
      } else {
        this.curCommand = "4";
        this.handleUseArtifact(artifactIndex);
      }
      return;
    }

    this.handleUseArtifact(artifactIndex);
  }

  handleCarryArtifact(artifactIndex) {
    this.currentRecord = this.artifactRecord[artifactIndex];
    this.getRecord();

    this.newPlace = parseInt(this.recordContent.substr(85, 4));

    if (this.newPlace !== 0) {
      this.currentRecord = this.newPlace;
      this.getRecord();
      this.executeAction();
      return;
    }

    if (this.carryCount >= 6) {
      this.currentRecord = 340;
      this.displayMessage();
      return;
    }

    this.carryCount++;
    this.artifactLocation[artifactIndex] = 0;
    this.executeCarryAction();
  }

  handleDropArtifact(artifactIndex) {
    if (this.artifactLocation[artifactIndex] !== 0) {
      this.currentRecord = 339;
      this.displayMessage();
      return;
    }

    this.carryCount--;
    if (this.carryCount < 0) this.carryCount = 0;
    this.placeArtifact(artifactIndex);
  }

  handleThrowArtifact(artifactIndex) {
    this.handleDropArtifact(artifactIndex);
    this.curCommand = "4";
    this.handleUseArtifact(artifactIndex);
  }

  handleUseArtifact(artifactIndex) {
    this.currentRecord = this.artifactRecord[artifactIndex];
    this.getRecord();

    this.curCommand = "X";
    for (let i = 66; i <= 74; i += 4) {
      if (this.word1 === this.recordContent.substr(i, 4)) {
        this.curCommand = String(Math.floor((i - 62) / 4));
        break;
      }
    }

    if (this.curCommand === "X") {
      this.currentRecord = 338;
      this.displayMessage();
      return;
    }

    this.curCommand = this.curCommand + String(Math.floor(artifactIndex / 100)).padStart(2, "0");
    this.executeAction();
  }

  placeArtifact(artifactIndex) {
    if (this.placeRecord.substr(89, 3) === "***") {
      this.artifactLocation[artifactIndex] = parseInt(this.placeRecord.substr(93, 4));
    } else {
      this.artifactLocation[artifactIndex] = this.currentRoom;
    }
  }

  // ================================================================
  // CONDITIONAL MOVEMENT
  // ================================================================

  processConditionalMovement() {
    const conditionType = parseInt(this.recordContent.substr(18, 1));

    switch (conditionType) {
      case 1:
      case 2:
        this.checkPlayerState();
        break;
      case 3:
        this.processSuccessfulCondition();
        break;
      case 4:
        this.processFailedCondition();
        break;
      case 5:
        this.processBothConditions();
        break;
    }
  }

  checkPlayerState() {
    const requiredState = parseInt(this.recordContent.substr(18, 1));

    if (requiredState !== this.playerState) {
      this.processFailedCondition();
    } else {
      this.processMandatoryItems();
    }
  }

  processMandatoryItems() {
    for (let offset = 0; offset < 10; offset += 2) {
      let itemNumber = this.recordContent.substr(19 + offset, 2);
      const parsedNum = this.parseItemNumber(itemNumber);

      if (parsedNum < 0) {
        if (this.gremlinLocation[-parsedNum] !== this.currentRoom) {
          this.processFailedCondition();
          return;
        }
      } else if (parsedNum > 0) {
        if (this.artifactLocation[parsedNum] !== 0) {
          this.processFailedCondition();
          return;
        }
      }

      itemNumber = this.recordContent.substr(31 + offset, 2);
      const parsedNum2 = this.parseItemNumber(itemNumber);

      if (parsedNum2 < 0) {
        if (this.gremlinLocation[-parsedNum2] === this.currentRoom) {
          this.processFailedCondition();
          return;
        }
      } else if (parsedNum2 > 0) {
        if (this.artifactLocation[parsedNum2] === 0) {
          this.processFailedCondition();
          return;
        }
      }
    }

    this.checkAdditionalConditions();
  }

  checkAdditionalConditions() {
    const savedRecord = this.recordContent;
    this.currentRecord = parseInt(this.recordContent.substr(43, 4));
    
    if (this.currentRecord === 0) {
      this.processSuccessfulCondition();
      return;
    }

    this.getRecord();
    const requiredState = this.recordContent.substr(8, 1);
    this.recordContent = savedRecord;

    if (this.recordContent.substr(47, 1) !== requiredState) {
      this.processFailedCondition();
      return;
    }

    if (parseInt(this.recordContent.substr(48, 1)) > Math.random() * 10) {
      this.processFailedCondition();
    } else {
      this.processSuccessfulCondition();
    }
  }

  processSuccessfulCondition() {
    this.currentRecord = parseInt(this.recordContent.substr(10, 4));
    this.action = this.recordContent.substr(0, 5);
    this.displayMessage();
    this.executeAction();
  }

  processFailedCondition() {
    this.currentRecord = parseInt(this.recordContent.substr(14, 4));
    this.action = this.recordContent.substr(5, 5);
    this.displayMessage();
    this.executeAction();
  }

  processBothConditions() {
    this.secondaryAction = this.recordContent.substr(5, 5);
    this.processSuccessfulCondition();
  }

  parseItemNumber(itemString) {
    const num = parseInt(itemString);
    
    if (itemString[itemString.length - 1] === "P") {
      return -num;
    }
    
    return num;
  }

  // ================================================================
  // COMPLEX ACTIONS
  // ================================================================

  processComplexMovement() {
    const savedRecord = this.recordContent;

    for (let i = 0; i < 86; i += 5) {
      this.currentRecord = parseInt(savedRecord.substr(i, 4));
      if (this.currentRecord === 0) break;

      this.getRecord();
      this.recordContent = this.recordContent.substr(0, 8) + savedRecord.substr(i + 4, 1) + 
                          this.recordContent.substr(9);
      this.saveRecord();
    }

    this.action = savedRecord.substr(90, 5);
    this.executeAction();
  }

  processSpecificTarget(targetIndex, operationType) {
    if (operationType === "1") {
      this.currentRecord = this.artifactRecord[targetIndex];
    } else {
      this.currentRecord = this.gremlinRecord[targetIndex];
    }
    this.processTargetAction();
  }

  processAllTargets(operationType) {
    this.foundTarget = 0;

    if (operationType === "1") {
      for (let i = 1; i <= this.numArtifacts; i++) {
        if (this.artifactLocation[i] === 0 || this.artifactLocation[i] === this.currentRoom) {
          this.checkTargetEligibility(i);
          if (this.foundTarget > 0) {
            this.currentRecord = this.artifactRecord[this.foundTarget];
            this.processTargetAction();
            return;
          }
        }
      }
    } else {
      for (let i = 1; i <= this.numGremlins; i++) {
        if (this.gremlinLocation[i] === this.currentRoom) {
          this.checkTargetEligibility(i);
          if (this.foundTarget > 0) {
            this.currentRecord = this.gremlinRecord[this.foundTarget];
            this.processTargetAction();
            return;
          }
        }
      }
    }

    this.currentRecord = 344;
    this.displayMessage();
  }

  checkTargetEligibility(index) {
    if (this.foundTarget === 0) {
      if (Math.random() * 10 > 2) return;
    }
    this.foundTarget = index;
  }

  processTargetAction() {
    this.getRecord();
    const actionFlag = parseInt(this.action[0]) - 3;

    switch (actionFlag) {
      case 0: this.processStateChange(); break;
      case 1: this.processLocationChange(); break;
      case 2: this.processLocationChange(); break;
      case 3: this.processDestroy(); break;
      case 4: this.executeCarryAction(); break;
      case 5: this.executeDropAction(); break;
    }
  }

  processStateChange() {
    const currentState = parseInt(this.recordContent.substr(8, 1));

    if (currentState === 1) {
      this.recordContent = this.recordContent.substr(0, 8) + "2" + this.recordContent.substr(9);
    } else {
      this.recordContent = this.recordContent.substr(0, 8) + "1" + this.recordContent.substr(9);
    }

    this.saveRecord();

    if (this.action.substr(2, 1) === "0") {
      this.playerState = parseInt(this.recordContent.substr(8, 1));
      this.placeRecord = this.recordContent;
    }

    this.currentRecord = parseInt(this.recordContent.substr(13 + 4 * parseInt(this.recordContent.substr(8, 1)), 4));
    this.displayMessage();
  }

  processLocationChange() {
    this.newPlace = parseInt(this.recordContent.substr(92, 4));

    if (this.newPlace !== this.currentRoom) {
      this.newPlace = this.warehouseRoom;
      if (this.newPlace === this.currentRoom) this.newPlace = 9999;
    }

    if (this.action.substr(2, 1) === "1") {
      if (this.artifactLocation[this.foundTarget] === 0) this.carryCount--;
      this.artifactLocation[this.foundTarget] = this.newPlace;
      this.currentRecord = 346;
      this.processObjectMessage();
    } else {
      this.gremlinLocation[this.foundTarget] = this.newPlace;
      if (this.action[0] === "1") {
        this.currentRecord = 346;
        this.processObjectMessage();
      } else {
        this.currentRecord = 347;
        this.processObjectMessage();
      }
    }
  }

  processDestroy() {
    if (this.action[0] === "9") {
      this.destroyObject();
      return;
    }

    this.textOutput = "A ";
    this.processTextOutput();
    this.processArtifactDescription();
    this.processDescription();
    this.currentRecord = 348;
    this.displayMessage();
    this.destroyObject();
  }

  destroyObject() {
    if (this.action.substr(2, 1) === "1") {
      if (this.artifactLocation[this.foundTarget] === 0) this.carryCount--;
      this.placeArtifact(this.foundTarget);
    } else {
      this.gremlinLocation[this.foundTarget] = -1;
    }
  }

  processObjectMessage() {
    if (this.action[0] === "9") return;
    
    const savedRecord = this.currentRecord;
    
    this.textOutput = "The ";
    this.processTextOutput();
    this.processArtifactDescription();
    this.processDescription();
    
    this.currentRecord = savedRecord;
    this.displayMessage();
  }

  // ================================================================
  // PLAYER ACTIONS
  // ================================================================

  handlePlayerDeath() {
    const deathMessage = this.action.substr(this.action.length - 4);
    this.currentRecord = parseInt(deathMessage);
    this.displayMessage();

    this.currentRecord = 345;
    this.displayMessage();
    this.flushOutput();

    // In a real implementation, would wait for user input
    this.output("Continue? (Y/N):");
    
    // For now, assume yes and continue
    this.moveCount += 10;

    for (let i = 1; i <= this.numArtifacts; i++) {
      if (this.artifactLocation[i] === 0) {
        this.placeArtifact(i);
      }
    }

    this.carryCount = 0;
    this.currentRoom = this.homeRoom;
    this.actionResult = "Y";
  }

  handlePlayerStateChange() {
    this.playerState = 1;
    this.placeRecord = this.placeRecord.substr(0, 8) + "1" + this.placeRecord.substr(9);
    this.recordContent = this.placeRecord;
    this.currentRecord = this.currentRoom;
    this.saveRecord();
    this.executeMoveAction();
  }

  handlePlayerMovement() {
    const scoreChange = this.action.substr(this.action.length - 4);
    this.parsedNumber = this.parseItemNumber(scoreChange);
    this.penaltyPoints += this.parsedNumber;

    this.action = this.secondaryAction;
    this.secondaryAction = "0";
    this.executeAction();
  }

  handlePlayerCommand() {
    this.curCommand = this.action.substr(1, 3);
    this.processCommand();
  }

  handlePlayerStateToggle() {
    this.currentRecord = parseInt(this.action.substr(this.action.length - 4));
    this.getRecord();

    const currentState = parseInt(this.recordContent.substr(8, 1));

    if (currentState === 1) {
      this.recordContent = this.recordContent.substr(0, 8) + "2" + this.recordContent.substr(9);
    } else {
      this.recordContent = this.recordContent.substr(0, 8) + "1" + this.recordContent.substr(9);
    }

    this.saveRecord();

    this.action = this.secondaryAction;
    this.secondaryAction = "0";
    if (this.action !== "0") this.executeAction();
  }

  // ================================================================
  // KEYWORD INTERACTIONS
  // ================================================================

  checkKeywordInteractions() {
    if (this.placeRecord.substr(25, 4) === "* KR") {
      this.currentRecord = parseInt(this.placeRecord.substr(29, 4));
      this.findActionInRecord();
      if (this.action !== "?") return;
    }

    for (let i = this.numGremlins; i >= 1; i--) {
      if (this.gremlinLocation[i] === this.currentRoom) {
        this.currentRecord = this.gremlinRecord[i];
        this.getRecord();
        if (this.recordContent.substr(25, 4) === "* KR") {
          this.currentRecord = parseInt(this.recordContent.substr(29, 4));
          this.findActionInRecord();
          if (this.action !== "?") return;
        }
      }
    }
  }

  findActionInRecord() {
    this.getRecord();
    let searchIndex = 33;

    while (searchIndex < 90) {
      if (this.recordContent.substr(searchIndex, 1) === "E") break;

      if (this.recordContent.substr(searchIndex, 3) === this.curCommand) {
        this.action = this.recordContent.substr(searchIndex + 3, 5);
        return;
      }

      if (this.recordContent.substr(searchIndex + 1, 2) === "??" && 
          this.recordContent.substr(searchIndex, 1) === this.curCommand[0]) {
        this.commandArgs = this.curCommand.substr(1, 2);
        this.action = this.recordContent.substr(searchIndex + 3, 5);
        return;
      }

      searchIndex += 8;
    }
  }

  processLocationDescription() {
    this.displayMessage();
  }

  // ================================================================
  // SAVE/LOAD GAME
  // ================================================================

  saveGame() {
    const saveData = {
      currentRoom: this.currentRoom,
      score: this.score,
      moveCount: this.moveCount,
      penaltyPoints: this.penaltyPoints,
      carryCount: this.carryCount,
      randomSeed: this.randomSeed,
      artifactLocation: this.artifactLocation.slice(),
      artifactRecord: this.artifactRecord.slice(),
      gremlinLocation: this.gremlinLocation.slice(),
      gremlinRecord: this.gremlinRecord.slice(),
      gremlinFactor: this.gremlinFactor.slice(),
      locationList: this.locationList.slice(),
      recentPlaces: this.recentPlaces.slice()
    };

    return JSON.stringify(saveData);
  }

  loadGame(saveDataString) {
    try {
      const saveData = JSON.parse(saveDataString);
      
      this.currentRoom = saveData.currentRoom;
      this.score = saveData.score;
      this.moveCount = saveData.moveCount;
      this.penaltyPoints = saveData.penaltyPoints;
      this.carryCount = saveData.carryCount;
      this.randomSeed = saveData.randomSeed;
      this.artifactLocation = saveData.artifactLocation.slice();
      this.artifactRecord = saveData.artifactRecord.slice();
      this.gremlinLocation = saveData.gremlinLocation.slice();
      this.gremlinRecord = saveData.gremlinRecord.slice();
      this.gremlinFactor = saveData.gremlinFactor.slice();
      this.locationList = saveData.locationList.slice();
      this.recentPlaces = saveData.recentPlaces.slice();
      
      this.arriveAtLocation();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ================================================================
  // DATA LOADING
  // ================================================================

  setDataRecords(records) {
    this.dataRecords = records;
  }

  // ================================================================
  // DEBUGGING
  // ================================================================

  displayGameStatus() {
    this.output("=== GAME STATUS ===");
    this.output("Current Room: " + this.currentRoom);
    this.output("Score: " + this.score);
    this.output("Moves: " + this.moveCount);
    this.output("Carrying: " + this.carryCount + " items");
    this.output("Player State: " + this.playerState);
    this.output("");
    
    this.output("Artifacts:");
    for (let i = 1; i <= this.numArtifacts; i++) {
      if (this.artifactLocation[i] === 0) {
        this.output("  Artifact " + i + " - CARRIED");
      } else if (this.artifactLocation[i] === this.currentRoom) {
        this.output("  Artifact " + i + " - HERE");
      }
    }
    
    this.output("Gremlins:");
    for (let i = 1; i <= this.numGremlins; i++) {
      if (this.gremlinLocation[i] === this.currentRoom) {
        this.output("  Gremlin " + i + " - HERE (Factor: " + this.gremlinFactor[i] + ")");
      }
    }
    
    this.output("==================");
  }
}

// ================================================================
// USAGE EXAMPLE
// ================================================================

// Example of how to use the game:
//
// const game = new QuestGame();
//
// // Set up output handler
// game.onOutput = (text) => {
//   console.log(text);
// };
//
// // Set up input handler
// game.onInput = async () => {
//   // Return user input from your UI
//   return await getUserInput();
// };
//
// // Load game data
// game.setDataRecords(loadDataFromFile());
//
// // Initialize and start
// game.initializeGame();
// game.loadGameData();
// game.validateGameState();
// game.actionResult = "Y";
// game.arriveAtLocation();
// await game.startGameLoop();

export default QuestGame;
