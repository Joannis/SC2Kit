public enum DebugCommand {
    case draw([DebugDrawable])
    var sc2: SC2APIProtocol_DebugCommand {
        var command = SC2APIProtocol_DebugCommand()
        
        if case .draw(let drawables) = self {
            var draw = SC2APIProtocol_DebugDraw()
            
            for drawable in drawables {
                switch drawable {
                case .text(let text):
                    draw.text.append(text.sc2)
                case .box(let debugBox):
                    draw.boxes.append(debugBox.sc2)
                case .sphere(let debugSPhere):
                    draw.spheres.append(debugSPhere.sc2)
                }
            }
            
            command.command = .draw(draw)
        }
        
        return command
    }
}

public enum DebugDrawable {
    case text(DebugString)
    case box(DebugBox)
    case sphere(DebugSphere)
}

public enum DebugPosition {
    case screen(x: Float, y: Float)
    case world(Position.World)
}

public struct DebugString: ExpressibleByStringLiteral {
    public var text: String
    public var color: DebugColor
    public var position: DebugPosition
    public var size: UInt32
    
    public init(text: String, color: DebugColor = .white, size: UInt32 = 30, position: DebugPosition) {
        self.text = text
        self.color = color
        self.size = size
        self.position = position
    }
    
    public init(stringLiteral value: String) {
        self.text = value
        self.color = .white
        self.size = 1
        self.position = .screen(x: 0, y: 0)
    }
    
    var sc2: SC2APIProtocol_DebugText {
        var text = SC2APIProtocol_DebugText()
        text.text = self.text
        text.color = color.sc2
        text.size = size
        
        switch position {
        case .screen(let x, let y):
            text.virtualPos.x = x
            text.virtualPos.y = y
        case .world(let position):
            text.worldPos = position.sc2
        }
        
        return text
    }
}

public struct DebugBox {
    public var from: Position.World
    public var to: Position.World
    public var color: DebugColor
    
    public init(
        from: Position.World,
        to: Position.World,
        color: DebugColor
    ) {
        self.from = from
        self.to = to
        self.color = color
    }
    
    var sc2: SC2APIProtocol_DebugBox {
        var box = SC2APIProtocol_DebugBox()
        
        box.min = from.sc2
        box.max = to.sc2
        box.color = color.sc2
        
        return box
    }
}

public struct DebugSphere {
    public var at: Position.World
    public var range: Float
    public var color: DebugColor
    
    public init(
        at: Position.World,
        range: Float,
        color: DebugColor
    ) {
        self.at = at
        self.range = range
        self.color = color
    }
    
    var sc2: SC2APIProtocol_DebugSphere {
        var sphere = SC2APIProtocol_DebugSphere()
        
        sphere.p = at.sc2
        sphere.r = range
        sphere.color = color.sc2
        
        return sphere
    }
}

public struct DebugColor {
    let red: UInt32
    let green: UInt32
    let blue: UInt32
    
    public init(red: UInt32, green: UInt32, blue: UInt32) {
        self.red = red
        self.green = green
        self.blue = blue
    }
    
    public static let red = DebugColor(red: .max, green: .min, blue: .min)
    public static let green = DebugColor(red: .min, green: .max, blue: .min)
    public static let blue = DebugColor(red: .min, green: .min, blue: .max)
    public static let black = DebugColor(red: .min, green: .min, blue: .min)
    public static let white = DebugColor(red: .max, green: .max, blue: .max)
    
    var sc2: SC2APIProtocol_Color {
        var color = SC2APIProtocol_Color()
        color.r = red
        color.r = green
        color.b = blue
        return color
    }
}
