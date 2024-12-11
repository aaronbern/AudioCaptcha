local ADDON_NAME, ns = ...

local addon = CreateFrame("Frame")
addon:RegisterEvent("TAXIMAP_OPENED")
addon:RegisterEvent("MAIL_SHOW")

addon:SetScript("OnEvent", function(self, event, ...)
    addon:OnEvent(event, ...)
end)

local captchaAnswer = nil
local captchaFrame = nil
local lastInteractionType = nil
local lastCaptchaSolveTime = 0
local captchaGracePeriod = 30 

local audioCaptchaFiles = {
    "0cpepi2d", "0t6tgpzv", "1qvpwr14", "30n7x4hg", "382jgc2x",
    "3ah7mfe2", "3y0ie7wa", "4rk5361u", "51zv5xz0", "5dz8cc7f",
    "5e47oyy8", "7sq5ywsa", "93upio4c", "96adzqn3", "97nh5nwd",
    "cdhzsy41", "cdw69r99", "e43pbrcn", "ennn2d8l", "f0nnpsad",
    "i0v6tc1o", "i2t0g03u", "jaamdhx3", "jcsdefbd", "k4fq0449",
    "kj8ocxuk", "l5szzlbi", "m08m7x31", "n9en1v08", "nhjdgkw3",
    "o0np4o0j", "odmoc5ur", "oss0zea3", "p4b5rdg9", "pogya4ip",
    "psitxz2f", "q8dgcft4", "qmmhp3zb", "r392m8sv", "rqq0xgd9",
    "s3my09ks", "si6i7aa4", "suxf4ybp", "tgc7c3gw", "twcilgd5",
    "w2ng4tgn", "x41w4993", "ybdmp2ag", "yfylw7yi", "zi2xv2sr",
}

local function PlayAudioCaptcha(answer)
    local filePath = "Interface\\AddOns\\FlightAudioCaptcha\\audio_captchas\\" .. answer .. ".wav"
    if not PlaySoundFile(filePath, "Master") then
        print("|cffff0000[Captcha]|r Failed to play audio file: " .. filePath)
    end
end

function addon:ShowAudioCaptchaFrame()
    if not captchaFrame then
        captchaFrame = CreateFrame("Frame", "AudioCaptchaFrame", UIParent, "BackdropTemplate")
        captchaFrame:SetSize(400, 200)
        captchaFrame:SetPoint("CENTER")
        captchaFrame:SetFrameStrata("DIALOG")
        captchaFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })

        local titleText = captchaFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        titleText:SetPoint("TOP", 0, -16)
        titleText:SetText("Listen to the audio and type the answer!")

        local editBox = CreateFrame("EditBox", nil, captchaFrame, "InputBoxTemplate")
        editBox:SetSize(120, 20)
        editBox:SetPoint("CENTER", 0, -10)
        editBox:SetAutoFocus(true)
        captchaFrame.editBox = editBox

        local playButton = CreateFrame("Button", nil, captchaFrame, "UIPanelButtonTemplate")
        playButton:SetSize(60, 20)
        playButton:SetPoint("BOTTOMLEFT", 10, 10)
        playButton:SetText("Play")
        playButton:SetScript("OnClick", function()
            PlayAudioCaptcha(captchaAnswer)
        end)

        local okButton = CreateFrame("Button", nil, captchaFrame, "UIPanelButtonTemplate")
        okButton:SetSize(60, 20)
        okButton:SetPoint("BOTTOMRIGHT", -10, 10)
        okButton:SetText("OK")
        okButton:SetScript("OnClick", function()
            local userAnswer = editBox:GetText()
            if userAnswer and userAnswer:lower() == captchaAnswer:lower() then
                captchaFrame:Hide()
                lastCaptchaSolveTime = GetTime() -- Update solve time
                addon:ResumeInteraction()
                print("|cffffd200[Captcha]|r Correct answer!")
            else
                StaticPopup_Show("AUDIO_CAPTCHA_WRONG")
            end
        end)

        local cancelButton = CreateFrame("Button", nil, captchaFrame, "UIPanelButtonTemplate")
        cancelButton:SetSize(60, 20)
        cancelButton:SetPoint("BOTTOM", 0, 10)
        cancelButton:SetText("Cancel")
        cancelButton:SetScript("OnClick", function()
            captchaFrame:Hide()
            lastInteractionType = nil
            print("|cffff0000[Captcha]|r You canceled the CAPTCHA.")
        end)

        -- Keybinding
        editBox:SetScript("OnEnterPressed", function()
            okButton:Click()
        end)
        editBox:SetScript("OnEscapePressed", function()
            cancelButton:Click()
        end)

        StaticPopupDialogs["AUDIO_CAPTCHA_WRONG"] = {
            text = "Incorrect answer, please try again.",
            button1 = "OK",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnAccept = function()
                editBox:SetText("")
                editBox:SetFocus()
            end,
        }
    end

    captchaAnswer = audioCaptchaFiles[math.random(#audioCaptchaFiles)]
    PlayAudioCaptcha(captchaAnswer)
    captchaFrame.editBox:SetText("")
    captchaFrame.editBox:SetFocus()
    captchaFrame:Show()
end

function addon:OnEvent(event, ...)
    local currentTime = GetTime()
    if currentTime - lastCaptchaSolveTime < captchaGracePeriod then
        print("|cffffd200[Captcha]|r You have free access during the grace period.")
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

function addon:ResumeInteraction()
    if lastInteractionType == "taxi" then
        print("|cffffd200[Captcha]|r Interact with the flight master again.")
    elseif lastInteractionType == "mail" then
        print("|cffffd200[Captcha]|r Interact with the mailbox again.")
    end
    lastInteractionType = nil
end
