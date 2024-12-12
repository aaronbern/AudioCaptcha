-- Local addon initialization
local ADDON_NAME, ns = ...

local addon = CreateFrame("Frame")
addon:RegisterEvent("TAXIMAP_OPENED")
addon:RegisterEvent("MAIL_SHOW")

addon:SetScript("OnEvent", function(self, event, ...)
    addon:OnEvent(event, ...)
end)

-- Variables to manage captcha state
local captchaAnswer = nil
local captchaFrame = nil
local lastInteractionType = nil
local lastCaptchaSolveTime = 0
local captchaGracePeriod = 30 
local isCaptchaActive = false -- Lock Mechanism Flag

-- List of audio captcha files
local audioCaptchaFiles = {
    "1j5w32m2",
    "1kxd2smd",
    "1xn2dzzg",
    "45yp26yk",
    "4gdkf1z2",
    "4wi2yx1c",
    "7bouzypr",
    "7ureikaj",
    "89friex6",
    "8bso6p56",
    "8kgos332",
    "8wy5jc9q",
    "a207l70h",
    "a9jpmdmo",
    "bgcxeshp",
    "bnzax5eh",
    "cffevbcl",
    "elbk9ru1",
    "fd9stqf3",
    "gdcig702",
    "gt8i5ouz",
    "hd34385s",
    "hhvd5rhc",
    "i0zn9iof",
    "jb4diicj",
    "jf8eufju",
    "jp5wqvyc",
    "k0663j73",
    "m511v0wm",
    "mz7mhwap",
    "mzwyra69",
    "nueyhlp4",
    "omyem3rq",
    "ppakxmlb",
    "r7jvlo7l",
    "rsp53xs5",
    "segnmnbb",
    "t1dz9trp",
    "tf928biq",
    "tzn22fh2",
    "ut0xeplj",
    "v2dgatff",
    "vh8iw4v4",
    "vmftm9f0",
    "vu4k8imb",
    "whf87omi",
    "y17flws5",
    "y2oaoevv",
    "yndhsg7i",
    "zmfs3sl8"
}

-- Function to play the selected audio captcha
local function PlayAudioCaptcha(answer)
    local filePath = "Interface\\AddOns\\FlightAudioCaptcha\\audio_captchas\\" .. answer .. ".wav"
    if not PlaySoundFile(filePath, "Master") then
        print("|cffff0000[Captcha]|r Failed to play audio file: " .. filePath)
    end
end

-- Function to create and display the captcha frame
function addon:ShowAudioCaptchaFrame()
    if not captchaFrame then
        -- Create the captcha frame
        captchaFrame = CreateFrame("Frame", "AudioCaptchaFrame", UIParent, "BackdropTemplate")
        captchaFrame:SetSize(400, 200)
        captchaFrame:SetPoint("CENTER")
        captchaFrame:SetFrameStrata("DIALOG")
        captchaFrame:SetToplevel(true) -- Ensure the frame is on top
        captchaFrame:SetClampedToScreen(true)
        captchaFrame:SetMovable(false)
        captchaFrame:EnableMouse(true)
        captchaFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })

        -- Title text
        local titleText = captchaFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        titleText:SetPoint("TOP", 0, -16)
        titleText:SetText("Listen to the audio and type the answer!")

        -- Edit box for user input
        local editBox = CreateFrame("EditBox", nil, captchaFrame, "InputBoxTemplate")
        editBox:SetSize(120, 20)
        editBox:SetPoint("CENTER", 0, -10)
        editBox:SetAutoFocus(true)
        captchaFrame.editBox = editBox

        -- Play button to replay the captcha audio
        local playButton = CreateFrame("Button", nil, captchaFrame, "UIPanelButtonTemplate")
        playButton:SetSize(60, 20)
        playButton:SetPoint("BOTTOMLEFT", 10, 10)
        playButton:SetText("Play")
        playButton:SetScript("OnClick", function()
            PlayAudioCaptcha(captchaAnswer)
        end)

        -- OK button to submit the captcha answer
        local okButton = CreateFrame("Button", nil, captchaFrame, "UIPanelButtonTemplate")
        okButton:SetSize(60, 20)
        okButton:SetPoint("BOTTOMRIGHT", -10, 10)
        okButton:SetText("OK")
        okButton:SetScript("OnClick", function()
            local userAnswer = editBox:GetText()
            if userAnswer and userAnswer:lower() == captchaAnswer:lower() then
                captchaFrame:Hide()
                lastCaptchaSolveTime = GetTime() -- Update solve time
                isCaptchaActive = false -- Release the lock
                addon:ResumeInteraction()
                print("|cffffd200[Captcha]|r Correct answer!")
            else
                StaticPopup_Show("AUDIO_CAPTCHA_WRONG")
            end
        end)

        -- Cancel button to abort the captcha
        local cancelButton = CreateFrame("Button", nil, captchaFrame, "UIPanelButtonTemplate")
        cancelButton:SetSize(60, 20)
        cancelButton:SetPoint("BOTTOM", 0, 10)
        cancelButton:SetText("Cancel")
        cancelButton:SetScript("OnClick", function()
            captchaFrame:Hide()

            -- Do not re-show the original frame to prevent immediate reopening
            -- Optionally, notify the user that they must solve the captcha to proceed
            print("|cffffd200[Captcha]|r Captcha canceled. You must solve the captcha to interact again.")

            isCaptchaActive = false -- Release the lock
            lastInteractionType = nil
        end)

        -- Keybinding: Pressing Enter in the edit box triggers the OK button
        editBox:SetScript("OnEnterPressed", function()
            okButton:Click()
        end)

        -- Handle Escape key to cancel the captcha via the editBox
        editBox:SetScript("OnEscapePressed", function()
            cancelButton:Click()
        end)

        -- Handle focus when the captcha frame is shown
        captchaFrame:SetScript("OnShow", function(self)
            -- Set focus to the editBox instead of using SetKeyboardFocus on the frame
            self.editBox:SetFocus()
        end)

        -- Static popup dialog for wrong captcha answers
        StaticPopupDialogs["AUDIO_CAPTCHA_WRONG"] = {
            text = "Incorrect answer, please try again.",
            button1 = "OK",
            timeout = 0,
            whileDead = true,
            preferredIndex = 3,
            OnAccept = function()
                editBox:SetText("")
                editBox:SetFocus()
            end,
        }
    end

    -- Select a random captcha answer
    captchaAnswer = audioCaptchaFiles[math.random(#audioCaptchaFiles)]
    PlayAudioCaptcha(captchaAnswer)
    captchaFrame.editBox:SetText("")
    captchaFrame.editBox:SetFocus()
    captchaFrame:Show()

    isCaptchaActive = true -- Activate the lock
end

-- Event handler function
function addon:OnEvent(event, ...)
    local currentTime = GetTime()
    if currentTime - lastCaptchaSolveTime < captchaGracePeriod then
        return
    end

    if isCaptchaActive then
        -- Block further interactions while captcha is active
        return
    end

    if event == "TAXIMAP_OPENED" and TaxiFrame and TaxiFrame:IsShown() then
        TaxiFrame:Hide()
        lastInteractionType = "taxi"
        addon:ShowAudioCaptchaFrame()
    elseif event == "MAIL_SHOW" then
        if MailFrame then
            C_Timer.After(0.1, function()
                if MailFrame:IsShown() then
                    MailFrame:Hide()
                    lastInteractionType = "mail"
                    addon:ShowAudioCaptchaFrame()
                else
                    print("|cffff0000[Captcha]|r MailFrame not shown at MAIL_SHOW.")
                end
            end)
        else
            print("|cffff0000[Captcha]|r MailFrame not accessible.")
        end
    end
end

-- Function to resume interaction after captcha is solved
function addon:ResumeInteraction()
    if lastInteractionType == "taxi" then
        print("|cffffd200[Captcha]|r You may now interact with the flight master.")
    elseif lastInteractionType == "mail" then
        print("|cffffd200[Captcha]|r You may now interact with the mailbox.")
    end
    lastInteractionType = nil
end
