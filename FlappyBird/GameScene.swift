//
//  GameScene.swift
//  FlappyBird
//
//  Created by patrick on 2018/12/28.
//  Copyright © 2018 patrick. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var floor1: SKSpriteNode!
    var floor2: SKSpriteNode!
    var bird: SKSpriteNode!
    
    let birdCategory : UInt32 = 0x1 << 0
    let pipeCategory : UInt32 = 0x1 << 1
    let floorCategory : UInt32 = 0x1 << 2
    
    enum GameStatus {
        case idle //初始化
        case running //游戏运行中
        case over   //游戏结束
    }
    
    lazy var gameOverLabel : SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Game Over"
        return label
    } ()
    
    lazy var metersLabel : SKLabelNode = {
        let label = SKLabelNode(text: "meters:0")
        label.verticalAlignmentMode = .top
        label.horizontalAlignmentMode = .center
        return label
    } ()
    
    var meters = 0 {
        didSet {
            metersLabel.text = "meters:\(meters)"
        }
    }
    
    
    var gameStatus: GameStatus = .idle
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor(red: 80.0/255.0, green: 192.0/255.0, blue: 203.0/255.0, alpha: 1.0)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        
        //set floors
        floor1 = SKSpriteNode(imageNamed: "floor")
        floor1.anchorPoint = CGPoint(x: 0, y: 0)
        floor1.position = CGPoint(x: 0, y: 0)
        floor1.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: floor1.size.width, height: floor1.size.height))
        floor1.physicsBody?.categoryBitMask = floorCategory
        addChild(floor1)
        
        floor2 = SKSpriteNode(imageNamed: "floor")
        floor2.anchorPoint = CGPoint(x: 0, y: 0)
        floor2.position = CGPoint(x: floor1.size.width, y: 0)
        floor2.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: floor2.size.width, height: floor2.size.height))
        floor2.physicsBody?.categoryBitMask = floorCategory
        addChild(floor2)
        
        bird = SKSpriteNode(imageNamed: "player1")
        bird.physicsBody = SKPhysicsBody(texture: bird.texture!, size: bird.size)
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.contactTestBitMask = floorCategory | pipeCategory
        addChild(bird)
        
        metersLabel.position = CGPoint(x: self.size.width / 2.0, y: self.size.height - 100)
        metersLabel.zPosition = 100
        addChild(metersLabel)
        
        shuffle()
    }
    
    func moveScene() {
        floor1.position = CGPoint(x: floor1.position.x - 1, y: floor1.position.y)
        floor2.position = CGPoint(x: floor2.position.x - 1, y: floor2.position.y)
        if floor1.position.x < -floor1.size.width {
            floor1.position = CGPoint(x: floor2.position.x + floor2.size.width, y: floor1.position.y)
        }
        if floor2.position.x < -floor2.size.width {
            floor2.position = CGPoint(x: floor1.position.x + floor1.size.width, y: floor2.position.y)
        }
        
        for pipe in self.children where pipe.name == "pipe" {
            if let pipeSprite = pipe as? SKSpriteNode {
                pipeSprite.position = CGPoint(x: pipeSprite.position.x - 1, y: pipeSprite.position.y)
                if pipeSprite.position.x < -pipeSprite.size.width / 2.0 {
                    pipeSprite.removeFromParent()
                }
            }
            
        }
    }
    
    func birdStartFly() {
        let flyAction = SKAction.animate(with: [SKTexture(imageNamed: "player1"), SKTexture(imageNamed: "player2"), SKTexture(imageNamed: "player3"), SKTexture(imageNamed: "player2")], timePerFrame: 0.15)
        bird.run(SKAction.repeatForever(flyAction), withKey: "fly")
    }
    
    func birdStopFly() {
        bird.removeAction(forKey: "fly")
    }
    
    func shuffle() {
        gameStatus = .idle
        removeAllPipesNode()
        gameOverLabel.removeFromParent()
        bird.position = CGPoint(x: self.size.width / 2.0, y: self.size.height / 2.0)
        bird.physicsBody?.isDynamic = false
        meters = 0
        birdStartFly()
    }
    
    func startGame() {
        gameStatus = .running
        bird.physicsBody?.isDynamic = true
        startCreateRandomPipesAction()
    }
    
    func gameOver() {
        gameStatus = .over
        stopCreateRandomPipesAction()
        birdStopFly()
        
        isUserInteractionEnabled = false
        
        addChild(gameOverLabel)
        
        gameOverLabel.position = CGPoint(x: self.size.width / 2.0, y: self.size.height)
        gameOverLabel.zPosition = 100;
        gameOverLabel.run(SKAction.move(by: CGVector(dx: 0, dy: -self.size.height / 2.0), duration: 0.5), completion: {
            self.isUserInteractionEnabled = true
        })
    }
    
    func startCreateRandomPipesAction() {
        let waitAction = SKAction.wait(forDuration: 3.5, withRange: 1.5)
        let generatePipeAction = SKAction.run {
            self.createRandomPipes()
        }
        run(SKAction.repeatForever(SKAction.sequence([waitAction, generatePipeAction])), withKey: "createPipe")
    }
    
    func stopCreateRandomPipesAction() {
        self.removeAction(forKey: "createPipe")
    }
    
    func createRandomPipes() {
        let height = self.size.height - self.floor1.size.height
        let pipeGap = CGFloat(arc4random_uniform(UInt32(bird.size.height))) + bird.size.height * 2.5
        let pipeWidth = CGFloat(60.0)
        
        let topPipeHeight = CGFloat(arc4random_uniform(UInt32(height - pipeGap)))
        let bottomPipeHeight = height - pipeGap - topPipeHeight;
        
        addPipes(topSize: CGSize(width: pipeWidth, height: topPipeHeight), bottomSize: CGSize(width: pipeWidth, height: bottomPipeHeight))
    }
    
    func addPipes(topSize:CGSize, bottomSize:CGSize) {
        let topTexture = SKTexture(imageNamed: "topPipe")
        let topPipe = SKSpriteNode(texture: topTexture, size: topSize)
        topPipe.name = "pipe"
        topPipe.position = CGPoint(x: self.size.width + topPipe.size.width / 2.0, y: self.size.height - topPipe.size.height / 2.0)
        topPipe.physicsBody = SKPhysicsBody(texture: topTexture, size: topPipe.size)
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.categoryBitMask = pipeCategory
        
        let bottomTexture = SKTexture(imageNamed: "bottomPipe")
        let bottomPipe = SKSpriteNode(texture: bottomTexture, size: bottomSize)
        bottomPipe.name = "pipe"
        bottomPipe.position = CGPoint(x: self.size.width + bottomPipe.size.width / 2.0, y: self.floor1.size.height + bottomPipe.size.height / 2.0)
        bottomPipe.physicsBody = SKPhysicsBody(texture: bottomTexture, size: bottomPipe.size)
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.categoryBitMask = pipeCategory
        
        addChild(topPipe)
        addChild(bottomPipe)
        
    }
    
    func removeAllPipesNode() {
        for pipe in self.children where pipe.name == "pipe" {
            pipe.removeFromParent()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if gameStatus != .running {
            return
        }
        var bodyA : SKPhysicsBody
        var bodyB : SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            bodyA = contact.bodyA
            bodyB = contact.bodyB
        } else {
            bodyA = contact.bodyB
            bodyB = contact.bodyA
        }
        if bodyA.categoryBitMask == birdCategory
        && (bodyB.categoryBitMask == pipeCategory || bodyB.categoryBitMask == floorCategory){
            gameOver()
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameStatus {
        case .idle:
            startGame()
        case .running:
            print("给小鸟一个向上的力")
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20))
        case .over:
            shuffle()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if gameStatus != .over {
            moveScene()
        }
        if gameStatus == .running {
            meters += 1
        }
    }
}
