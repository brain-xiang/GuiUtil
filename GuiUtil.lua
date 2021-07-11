-- Gui Util
-- Legenderox
-- January 22, 2021



local GuiUtil = {}
local TweenService = game:GetService("TweenService")

function GuiUtil:getProperty(instance, propertyName)
    local property;
    
    pcall(function()
        if typeof(instance[propertyName]) ~= "Instance" then 
            property = instance[propertyName]
        end
    end)

    return property
end

function GuiUtil:getChildrenOfClass(instance, className)
    --[[
        input: className = string
        returns: tbl, children
    ]]

    local childrenOfClass = {}
    for i,child in pairs(instance:GetChildren()) do
        if child.ClassName == className then
            table.insert(childrenOfClass, child)
        end
    end
    return childrenOfClass
end

function GuiUtil:getDescendantsOfClass(instance, className)
    --[[
        input: className = string
        returns: tbl, children
    ]]

    local children = instance:GetDescendants()
    for i,child in pairs(children) do
        if child.ClassName ~= className then
            table.remove(children, i)
        end
    end
    return children
end

function GuiUtil:fadeInPreset(guis, parentGui, time)
    --[[
        input: gui = table of GuiObjects, parentGui = GuiObject, holds the guis
        Fades the guis in using their presets.
        returns: lastTween, the last activated tween object
    ]]

    table.insert(guis, parentGui)
    local lastTween;
    if self:getProperty(parentGui, "Enabled") ~= nil then
        parentGui.Enabled = true
    elseif self:getProperty(parentGui, "Visible") ~= nil then
        parentGui.Visible = true
    else
        error(parentGui.Name.. " - ParentGui(guis[1]) Does not have Visible or Enabled properties")
        return
    end
    for i,element in pairs(guis) do
        local Properties = {
            BackgroundTransparency = self:getProperty(element, "BackgroundTransparency"),
            ImageTransparency = self:getProperty(element, "ImageTransparency"),
            TextTransparency = self:getProperty(element, "TextTransparency"),
            TextStrokeTransparency = self:getProperty(element, "TextStrokeTransparency"),
        }

        for Transparency, v in pairs(Properties) do
            element[Transparency] = 1
        end
        local tweenInfo = TweenInfo.new(time)
        local tween = TweenService:Create(element, tweenInfo, Properties)
        tween:Play()
        lastTween = tween
    end

    return lastTween
end

function GuiUtil:fadeOutPreset(guis, parentGui, time)
    --[[
        input: gui = table of GuiObjects, parentGui = GuiObject, holds the guis
        Fades the guis out using their presets.
        returns: firstTween, the first activated tween object
    ]]
    
    table.insert(guis, parentGui)
    local firstTween;
    for i,element in pairs(guis) do
        local Properties = {
            BackgroundTransparency = self:getProperty(element, "BackgroundTransparency"),
            ImageTransparency = self:getProperty(element, "ImageTransparency"),
            TextTransparency = self:getProperty(element, "TextTransparency"),
            TextStrokeTransparency = self:getProperty(element, "TextStrokeTransparency"),
        }

        local tweenInfo = TweenInfo.new(time)
        local tween = TweenService:Create(element, tweenInfo, {
            BackgroundTransparency = Properties.BackgroundTransparency and 1 or nil,
            ImageTransparency = Properties.ImageTransparency and 1 or nil,
            TextTransparency = Properties.TextTransparency and 1 or nil,
            TextStrokeTransparency = Properties.TextStrokeTransparency and 1 or nil,
        })
        tween:Play()
        firstTween = firstTween or tween
        
        tween.Completed:Connect(function()
            for Transparency, v in pairs(Properties) do
                element[Transparency] = v
            end
        end)
    end

    firstTween.Completed:Connect(function()
        if self:getProperty(parentGui, "Enabled") ~= nil then
            parentGui.Enabled = false
        elseif self:getProperty(parentGui, "Visible") ~= nil then
            parentGui.Visible = false
         else
            error(parentGui.Name.. " - ParentGui(guis[1]) Does not have Visible or Enabled properties")
            return
        end
    end)
    
    return firstTween
end

function GuiUtil:popInPreset(gui, tweenInfo)
    --[[
        input: gui = GuiObject, tweenInfo = TweenInfo
        pops the gui in using it's presets.
        returns: tween
    ]]

    local preset = gui.Size
    gui.Size = UDim2.new(0,0,0,0)
    gui.Visible = true

    local tween = TweenService:Create(gui, tweenInfo, {Size = preset})
    tween:Play()

    return tween 
end

function GuiUtil:getScrollingFrameAbsoluteSize(scrollingFrame)
    --[[
        input: scrollingFrame: Instance
        returns: Vector2, actual absoluteSize for scrolling frame, accounting for extended canvas size if it is bigger than normal absolutesize
    ]]

    local canvasSizeOffset = self:scaleToOffset(scrollingFrame.CanvasSize, scrollingFrame.Parent)
    local absoluteX = math.max(canvasSizeOffset.X.Offset, scrollingFrame.AbsoluteSize.X)
    local absoluteY = math.max(canvasSizeOffset.Y.Offset, scrollingFrame.AbsoluteSize.Y)

    return Vector2.new(absoluteX, absoluteY)
end

function GuiUtil:offsetToScale(size, parent)
    --[[
        input: size = Udim2
        returns: Udim2, size converted to scale in porportion to parent
    ]]

    local absoluteSize;-- Vector2
    if parent then
        absoluteSize = parent:IsA("ScrollingFrame") and self:getScrollingFrameAbsoluteSize(parent) or parent.AbsoluteSize
    else
        absoluteSize = workspace.CurrentCamera.ViewportSize
    end
    return UDim2.new((size.X.Offset / absoluteSize.X) + size.X.Scale, 0, (size.Y.Offset / absoluteSize.Y) + size.Y.Scale, 0)
end

function GuiUtil:scaleToOffset(size, parent)
    --[[
        input: size = Udim2
        returns: Udim2, size converted to offset in porportion to parent
    ]]
    local absoluteSize;-- Vector2
    if parent then
        absoluteSize = parent:IsA("ScrollingFrame") and self:getScrollingFrameAbsoluteSize(parent) or parent.AbsoluteSize
    else
        absoluteSize = workspace.CurrentCamera.ViewportSize
    end
    return UDim2.new(0, (size.X.Scale * absoluteSize.X) + size.X.Offset, 0, (size.Y.Scale * absoluteSize.Y) + size.Y.Offset)
end

function GuiUtil:absoluteToLocalPosition(absolutePosition, localElement)
    --[[
        input: absolutePosition = Vector2, localElement = GuiObject, parent/local element the position will be localised for
        returns: Udim2 offset, An absolute Position on the screen in form of a local position to the element provided
    ]]
    local x = absolutePosition.X - localElement.AbsolutePosition.X
    local y = absolutePosition.Y - localElement.AbsolutePosition.Y
    return UDim2.new(0, x, 0, y)
end

function GuiUtil:getCenter(pos, anchorPoint, absoluteSize)
    --[[
        input: pos = Udim2, anchorPoint, absoluteSize = Vector2
        returns: Udim2 (mixed if pos = scale), relative centerposition, pos + centerOffset (how many pixels the offset is from center)
    ]]
    return pos + UDim2.new(0, (0.5 - anchorPoint.X)*absoluteSize.X, 0, (0.5 - anchorPoint.Y)*absoluteSize.Y)
end

function GuiUtil:getAbsoluteCenter(guiOrPos, absoluteSize)
    --[[
        input: 
            guiOrPos, absoluteSize = vector2
            
            or:

            guiOrPos = GuiObject, absoluteSize = nil
        returns: vector2, Absolute center of the gui
    ]]
    if typeof(guiOrPos) == "Vector2" and typeof(absoluteSize) == "Vector2" then
        return Vector2.new(guiOrPos.X + (absoluteSize.X/2), guiOrPos.Y + (absoluteSize.Y/2))
    elseif guiOrPos:IsA("GuiButton") then
        return Vector2.new(guiOrPos.AbsolutePosition.X + (guiOrPos.AbsoluteSize.X/2), guiOrPos.AbsolutePosition.Y + (guiOrPos.AbsoluteSize.Y/2))
    end
    warn("getAbsoluteCenter got invalid args")
    return nil
end

function GuiUtil:typeWriteByDuration(label, text, duration)
    --[[
        input: label = TextLabel, text = string, duration = int
        Writes out text onto label one character at a time, in the duration provided
    ]]
    if duration / #text < 0.03 then error(tostring(duration).. " seconds is too short to typeWrite ".. tostring(#text).. " characters.") end

    label.Text = ""
    label.Visible = true
    for i = 1, #text do
        label.Text = string.sub(text, 1, i)
        wait(duration/#text)
    end
end

function GuiUtil:typeWriteByDelay(label, text, delay)
    --[[
        input: label = TextLabel, text = string, delay = int, waitFunc = function, specify wait function like RenderStepped
        Writes out text onto label one character at a time, waiting "delay" between each letter
    ]]

    label.Text = ""
    label.Visible = true
    for i = 1, #text do
        label.Text = string.sub(text, 1, i)
        wait(delay)
    end
end

function GuiUtil:disperseRandomlyInArea(guis, center, size, tweenInfo, delay)
    --[[
        input: guis = tbl, center = Vector2, center position of area, size = Vector2, area size, tweenInfo = TweenInfo, secified tweeninfo for tween
        tweens gui to random positions in the area (calculated using center and size)
        returns: tween, Last tween that was played
    ]]
    tweenInfo = tweenInfo or TweenInfo.new()
    local lastTween;
    for i,gui in pairs(guis) do
        local offsetX = math.random(-size.X/2, size.X/2)
        local offsetY = math.random(-size.Y/2, size.Y/2)
        local offset = Vector2.new(offsetX, offsetY)
        local endPos = GuiUtil:absoluteToLocalPosition(center + offset, gui.Parent)

        local tween = TweenService:Create(gui, tweenInfo, {Position = endPos})
        tween:Play()
        lastTween = tween
        if delay then 
            wait(delay)
        end
    end

    return lastTween
end

function GuiUtil:getPropertiesBridgingGap(Point1, Point2)
    --[[
        input: vector2's
        
        calculates the properties a gui Object needs to fill the gap between Point1 and Point2

        returns: position = Udim2, Rotation = int, length = int
    ]]
    local connectingVector = Point2 - Point1
    local flatVector = Vector2.new(connectingVector.X, 0)
    
    local length = connectingVector.Magnitude
    local position = Point1 + (connectingVector * 0.5)
    position = UDim2.new(0, position.X, 0, position.Y) -- converting to Udim

    -- calculating inverse since magnitude gets rid of negatives, 1 or -1
    local inverse = (connectingVector.X / math.abs(connectingVector.X)) * (connectingVector.Y / math.abs(connectingVector.Y)) 
    local rotation = math.deg(math.acos(flatVector.Magnitude/connectingVector.Magnitude)) * inverse

    return position, rotation, length
end

function GuiUtil:absuluteRotation(degrees)
    --[[
        input: int, gui rotation degrees
        returns: degrees converted to 1-360
    ]]
    return degrees%360
end

function GuiUtil:rotateAroundAnchorPoint(gui, endRotation, zeroDegPos, originalAnchorPoint)
    --[[
        input: gui = GuiObject, endRotation = int, desired rotation in degrees zeroDegPos = Udim2, .Position of gui (relative to parent) originalAnchorPoint = Vector2, original anchor point of gui at zero degree
        rotates gui around its anchor point instead of center
        
        NOTE: Anchor point will be changed to 0.5,0.5

        returns: Position = Udim2, Scale, Rotation = int
    ]]

    -- turning into offset but storing as vector 2 to preserve decimals
    zeroDegPos = Vector2.new((zeroDegPos.X.Scale * gui.Parent.AbsoluteSize.X) + zeroDegPos.X.Offset, (zeroDegPos.Y.Scale * gui.Parent.AbsoluteSize.Y) + zeroDegPos.Y.Offset)
    
    -- adding center offset to find innitial vector from parent 0,0 to zerodegPos center pos in offset
    local aVector = Vector2.new((0.5 - originalAnchorPoint.X)*gui.AbsoluteSize.X, (0.5 - originalAnchorPoint.Y)*gui.AbsoluteSize.Y)
    endRotation = self:absuluteRotation(endRotation) -- endRotation converted to 1-360
    endRotation -= endRotation > 180 and 360 or 0 -- converting to -180 to 180
    endRotation = endRotation
    local cosR = math.cos(math.rad(endRotation)) -- cos(endRotation)

    -- no rotation needed
    if endRotation == 0 then
        return gui.Position, gui.Rotation
    end

    -- variables for algebra
    local r = aVector.Magnitude -- radius of circle created by all possible points when rotating around anchorPOint
    local m = aVector.X -- Starting x
    local n = aVector.Y -- starting Y
    local S = r^2 * cosR -- rounded Scalar product
    
    -- graph for equations: https://www.desmos.com/calculator/fhimjcusr4

    -- n>0 and positive rotation, n<0 and negative rotation
    local x1 = (m*S - math.sqrt( n^2*(m^2 * r^2 + n^2 * r^2 - S^2)) ) / (m^2 + n^2) -- rounding since Udim2 offset is automaticly floored
    local y1 = (n^2 * S + m * math.sqrt( n^2 * (m^2 * r^2 + n^2 * r^2 - S^2)) ) / (m^2 * n + n^3)

    -- n>0 and negative rotation, n<0 and positive rotation
    local x2 = (m*S + math.sqrt( n^2*(m^2 * r^2 + n^2 * r^2 - S^2)) ) / (m^2 + n^2)
    local y2 = (n^2 * S - m * math.sqrt( n^2 * (m^2 * r^2 + n^2 * r^2 - S^2)) ) / (m^2 * n + n^3) 

    -- equation for when n = 0 (inverted so it does not devide by 0)

    -- m>0 and positive rotation, m<0 and negative rotation
    local x3 = (m^2 * S - n * math.sqrt( m^2 * (n^2 * r^2 + m^2 * r^2 - S^2)) ) / (n^2 * m + m^3)
    local y3 = (n*S + math.sqrt( m^2*(n^2 * r^2 + m^2 * r^2 - S^2)) ) / (n^2 + m^2)

    -- m>0 and negative rotation, m<0 and positive rotation
    local x4 = (m^2 * S + n * math.sqrt( m^2 * (n^2 * r^2 + m^2 * r^2 - S^2)) ) / (n^2 * m + m^3) 
    local y4 = (n*S - math.sqrt( m^2*(n^2 * r^2 + m^2 * r^2 - S^2)) ) / (n^2 + m^2)

    gui.AnchorPoint = Vector2.new(0.5,0.5)
    if r == 0 then -- Center Pos is on parent pos, only needs to rotate dont need repositioning
        local pos = zeroDegPos
        return UDim2.new((pos.X / gui.Parent.AbsoluteSize.X), 0, (pos.Y / gui.Parent.AbsoluteSize.Y), 0), endRotation        
    end

    -- check if inverted equation needed
    if n == 0 then
        if (m>0 and endRotation > 0) or (m<0 and endRotation<0) then
            -- x3: m>0 and positive rotation, m<0 and negative rotation
            local pos = Vector2.new(x3,y3) + zeroDegPos
            return UDim2.new((pos.X / gui.Parent.AbsoluteSize.X), 0, (pos.Y / gui.Parent.AbsoluteSize.Y), 0), endRotation  
        else
            -- x4: m>0 and negative rotation, m<0 and positive rotation
            local pos = Vector2.new(x4,y4) + zeroDegPos
            return UDim2.new((pos.X / gui.Parent.AbsoluteSize.X), 0, (pos.Y / gui.Parent.AbsoluteSize.Y), 0), endRotation  
        end
    end

    -- normal equations
    if (n>0 and endRotation > 0) or (n<0 and endRotation<0) then
        -- x1: n>0 and positive rotation, n<0 and negative rotation
        local pos = Vector2.new(x1,y1) + zeroDegPos
        return UDim2.new((pos.X / gui.Parent.AbsoluteSize.X), 0, (pos.Y / gui.Parent.AbsoluteSize.Y), 0), endRotation 
    else
        -- x2: n>0 and negative rotation, n<0 and positive rotation
        local pos = Vector2.new(x2,y2) + zeroDegPos
        return UDim2.new((pos.X / gui.Parent.AbsoluteSize.X), 0, (pos.Y / gui.Parent.AbsoluteSize.Y), 0), endRotation 
    end
end

function GuiUtil:calculateCanvasSizeForScrollingFrameWithList(UIListLayout, listElementTemplate, amount)
    --[[
        input: 
            UIListLayout = instance, 
            listElementTemplate = instance, template for elements used in list, 
            amount: amount of elements in list
        NOTE: if UIListLayout.padding is scale it will be transformed into offset using parentFrame.size not canvas size
        returns: UDim2 offset, canvas size to fit the amount of elements 
    ]]

    local padding = self:scaleToOffset(UDim2.new(UIListLayout.Padding), UIListLayout.Parent).X.Offset -- converting to studds
    local vertical = UIListLayout.FillDirection == Enum.FillDirection.Vertical
    local totalElementSize = vertical and padding + listElementTemplate.AbsoluteSize.Y or padding + listElementTemplate.AbsoluteSize.X -- including padding
    local totalLength = amount * totalElementSize

    return vertical and UDim2.new(0,0,0,totalLength) or UDim2.new(0,totalLength,0,0)
end

function GuiUtil:calculateCanvasSizeForScrollingFrameWithGrid(UIGridLayout, amount, axis)
    --[[
        input: 
            UIListLayout = instance, 
            amount: amount of elements in grid, 
            axis = str, "X" or "Y" determines which axis of canvas size is expanded to fit amount

        returns: UDim2 offset, canvas size to fit the amount of elements 
    ]]

    local scrollingFrame = UIGridLayout.Parent
    local constantAxis = axis == "X" and "Y" or "X"
    
    local padding = self:scaleToOffset(UIGridLayout.CellPadding, scrollingFrame) -- Udim2, offset
    local cellSize = self:scaleToOffset(UIGridLayout.CellSize, scrollingFrame) -- Udim2, offset
    local elementTotalSize = Vector2.new(cellSize.X.Offset + padding.X.Offset, cellSize.Y.Offset + padding.Y.Offset)

    local elementPerRowConstantSide = math.floor(scrollingFrame.AbsoluteSize[constantAxis] / elementTotalSize[constantAxis]) -- amount of elements can stack up on constant side before creating new row
    local rows = math.floor(amount/elementPerRowConstantSide + 1)

    local totalLength = rows * elementTotalSize[axis]

    return axis == "X" and UDim2.new(0,totalLength,0,0) or UDim2.new(0,0,0,totalLength)
end

function GuiUtil:getSizeWithAspectRatio(guiSize, parentSize, dominantAxis, ratio)
    --[[
        input:
            gui: UDim2 = size for gui the aspect ratio is made for
            parentSize = vector2, size of parent frame
            dominantAxis: str "X" or "Y" = determines which axis the other one should match with the ratio
            ratio: float = the ration between the dominantAxis and recessiveAxis, Dominant * ratio = recessive

        
        returns: Udim2, where the scale of the recessiveAxis has been changed to match the "ratio" of the dominantAxis (dominantAxis * ratio)
        NOTE: if desired size is less than the offset constant on then return nil
        ]]

    local recessiveAxis = dominantAxis == "X" and "Y" or "X"

    local dominantSideScale = guiSize[dominantAxis].Scale
    local dominantSideParentLength = parentSize[dominantAxis]
    local recessiveSideParentLength = parentSize[recessiveAxis]

    local recessiveSideOffset = guiSize[recessiveAxis].Offset
    local recessiveSideScale = ((dominantSideScale * dominantSideParentLength * ratio) + guiSize[dominantAxis].Offset) / recessiveSideParentLength

    return recessiveAxis == "X" and UDim2.new(recessiveSideScale, 0, dominantSideScale, guiSize.Y.Offset) or UDim2.new(dominantSideScale, guiSize.X.Offset, recessiveSideScale, 0)
end

return GuiUtil