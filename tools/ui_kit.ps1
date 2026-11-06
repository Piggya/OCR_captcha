# ui_kit.ps1
# -----------------------------------------------------------------------------
# Small WinForms drawing helpers used by panel.ps1.
#
# Everything here is owner-drawn with System.Drawing because plain WinForms
# looks like Windows 7. No third-party UI library is used: the portable package
# ships an embeddable Python and cannot add NuGet packages, and we want the
# panel to stay a single dependency-free PowerShell script.
#
# Conventions:
#   - All colours live in $script:ui so the whole look can be rethemed in one
#     place.
#   - Rounded corners are clipped with a GraphicsPath so panels look like
#     cards instead of boxes.
# -----------------------------------------------------------------------------

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$script:ui = @{
    Bg          = [System.Drawing.Color]::FromArgb(244, 246, 249)   # window
    Card        = [System.Drawing.Color]::White
    CardBorder  = [System.Drawing.Color]::FromArgb(226, 231, 238)
    HeaderBg    = [System.Drawing.Color]::FromArgb(30, 41, 59)      # slate-800
    HeaderText  = [System.Drawing.Color]::FromArgb(248, 250, 252)
    HeaderSub   = [System.Drawing.Color]::FromArgb(148, 163, 184)
    Text        = [System.Drawing.Color]::FromArgb(30, 41, 59)
    TextMuted   = [System.Drawing.Color]::FromArgb(100, 116, 139)
    Accent      = [System.Drawing.Color]::FromArgb(37, 99, 235)     # blue-600
    AccentHover = [System.Drawing.Color]::FromArgb(29, 78, 216)
    AccentDown  = [System.Drawing.Color]::FromArgb(30, 64, 175)
    Green       = [System.Drawing.Color]::FromArgb(22, 163, 74)
    Amber       = [System.Drawing.Color]::FromArgb(217, 119, 6)
    Red         = [System.Drawing.Color]::FromArgb(220, 38, 38)
    SoftBg      = [System.Drawing.Color]::FromArgb(248, 250, 252)
    SoftBorder  = [System.Drawing.Color]::FromArgb(203, 213, 225)
    Danger      = [System.Drawing.Color]::FromArgb(185, 28, 28)
}

function New-RoundedPath([int]$w, [int]$h, [int]$r) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    if ($r -le 0 -or $w -le 2 -or $h -le 2) {
        $path.AddRectangle((New-Object System.Drawing.Rectangle 0, 0, $w, $h))
        return $path
    }
    $d = $r * 2
    $path.AddArc(0, 0, $d, $d, 180, 90)
    $path.AddArc($w - $d - 1, 0, $d, $d, 270, 90)
    $path.AddArc($w - $d - 1, $h - $d - 1, $d, $d, 0, 90)
    $path.AddArc(0, $h - $d - 1, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function Set-RoundedRegion($control, [int]$radius) {
    if ($control.Width -le 0 -or $control.Height -le 0) { return }
    $path = New-RoundedPath $control.Width $control.Height $radius
    $old = $control.Region
    $control.Region = New-Object System.Drawing.Region $path
    $path.Dispose()
    if ($old) { $old.Dispose() }
}

# ------------------------------------------------------------------- buttons --
# WinForms button with FlatStyle + a custom Paint handler: rounded corners,
# hover/pressed colours, optional outlined ("ghost") variant and an accent
# variant for the primary action.
function New-StyleButton {
    param(
        [string]$Text = "",
        [int]$Width = 120,
        [int]$Height = 36,
        [ValidateSet("accent", "ghost", "danger")]
        [string]$Variant = "ghost",
        [scriptblock]$OnClick = $null
    )

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Size = New-Object System.Drawing.Size($Width, $Height)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9.5)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.TabStop = $true
    $btn.Tag = @{ Variant = $Variant; Hover = $false; Down = $false }

    $btn.Add_Paint({
        param($s, $e)
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $st = $s.Tag
        $ui = $script:ui
        # NOTE: never read a script-level variable called $ui here. This
        # handler shares scope with the click handler that gets attached by
        # Add_Click, and New-StyleButton's own $Text/$Variant parameters leak
        # into that same scope, which used to clobber $ui.

        $radius = [Math]::Max(6, [int]($s.Height / 2) - 2)
        $path = New-RoundedPath $s.Width $s.Height $radius

        switch ($st.Variant) {
            "accent" {
                $bg = $(if ($st.Down) { $ui.AccentDown } elseif ($st.Hover) { $ui.AccentHover } else { $ui.Accent })
                $fg = [System.Drawing.Color]::White
                $border = $null
            }
            "danger" {
                $bg = $(if ($st.Down) { [System.Drawing.Color]::FromArgb(153, 27, 27) } else { $ui.SoftBg })
                $fg = $(if ($st.Hover) { [System.Drawing.Color]::White } elseif ($st.Down) { [System.Drawing.Color]::White } else { $ui.Danger })
                $border = $ui.Danger
            }
            default {
                $bg = $(if ($st.Down) { [System.Drawing.Color]::FromArgb(226, 232, 240) } elseif ($st.Hover) { [System.Drawing.Color]::FromArgb(239, 246, 255) } else { $ui.SoftBg })
                $fg = $(if ($st.Hover) { $ui.Accent } else { $ui.Text })
                $border = $ui.SoftBorder
            }
        }

        $brush = New-Object System.Drawing.SolidBrush $bg
        $g.FillPath($brush, $path)
        $brush.Dispose()
        if ($border) {
            $pen = New-Object System.Drawing.Pen $border, 1
            $g.DrawPath($pen, $path)
            $pen.Dispose()
        }

        $fmt = New-Object System.Drawing.StringFormat
        $fmt.Alignment = [System.Drawing.StringAlignment]::Center
        $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
        $rect = New-Object System.Drawing.RectangleF 0, 0, $s.Width, $s.Height
        $tb = New-Object System.Drawing.SolidBrush $fg
        $g.DrawString($s.Text, $s.Font, $tb, $rect, $fmt)
        $tb.Dispose()
        $fmt.Dispose()
        $path.Dispose()
    })

    $btn.Add_MouseEnter({ $s = $args[0]; $s.Tag.Hover = $true; $s.Invalidate() })
    $btn.Add_MouseLeave({ $s = $args[0]; $s.Tag.Hover = $false; $s.Tag.Down = $false; $s.Invalidate() })
    $btn.Add_MouseDown({ $s = $args[0]; $s.Tag.Down = $true; $s.Invalidate() })
    $btn.Add_MouseUp({ $s = $args[0]; $s.Tag.Down = $false; $s.Invalidate() })

    if ($OnClick) { $btn.Add_Click($OnClick) }
    return $btn
}

# -------------------------------------------------------------------- cards --
# A rounded white card that can host child controls.
function New-Card {
    param(
        [int]$Width = 300,
        [int]$Height = 120,
        [string]$Title = "",
        [int]$Radius = 10
    )
    $card = New-Object System.Windows.Forms.Panel
    $card.Size = New-Object System.Drawing.Size($Width, $Height)
    $card.BackColor = $script:ui.Bg
    $card.Tag = @{ Title = $Title; Radius = $Radius }
    $card.Add_Paint({
        param($s, $e)
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $ui = $script:ui
        $path = New-RoundedPath $s.Width $s.Height $s.Tag.Radius
        $brush = New-Object System.Drawing.SolidBrush $ui.Card
        $g.FillPath($brush, $path)
        $brush.Dispose()
        $pen = New-Object System.Drawing.Pen $ui.CardBorder, 1
        $g.DrawPath($pen, $path)
        $pen.Dispose()
        if ($s.Tag.Title) {
            $tf = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
            $tb = New-Object System.Drawing.SolidBrush $ui.Text
            $g.DrawString($s.Tag.Title, $tf, $tb, 16, 12)
            $tb.Dispose()
            $tf.Dispose()
        }
        $path.Dispose()
    })
    return $card
}

# -------------------------------------------------------------------- misc ---
function New-Label {
    param(
        [string]$Text = "",
        [System.Drawing.Font]$Font = $null,
        [System.Drawing.Color]$Color = [System.Drawing.Color]::Empty,
        [bool]$Bold = $false,
        [float]$Size = 9
    )
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Text
    $lbl.AutoSize = $true
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    $style = $(if ($Bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular })
    $lbl.Font = $(if ($Font) { $Font } else { New-Object System.Drawing.Font("Microsoft YaHei UI", $Size, $style) })
    if ($Color -ne [System.Drawing.Color]::Empty) {
        $lbl.ForeColor = $Color
    } else {
        $lbl.ForeColor = $script:ui.Text
    }
    return $lbl
}

function New-StyledTextbox {
    param([int]$Width = 300)
    $box = New-Object System.Windows.Forms.TextBox
    $box.BorderStyle = "None"
    $box.ReadOnly = $true
    $box.Font = New-Object System.Drawing.Font("Consolas", 9.5)
    $box.BackColor = $script:ui.SoftBg
    $box.ForeColor = $script:ui.Text
    $box.Size = New-Object System.Drawing.Size($Width, 22)
    return $box
}

# Rounded "well" that visually wraps a textbox (the textbox itself is borderless).
function New-InputWell {
    param(
        [System.Windows.Forms.TextBox]$Box,
        [int]$Width = 470,
        [int]$Height = 30
    )
    $well = New-Object System.Windows.Forms.Panel
    $well.Size = New-Object System.Drawing.Size($Width, $Height)
    $well.BackColor = $script:ui.Card
    $well.Add_Paint({
        param($s, $e)
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $path = New-RoundedPath $s.Width $s.Height 7
        $brush = New-Object System.Drawing.SolidBrush $script:ui.SoftBg
        $g.FillPath($brush, $path)
        $brush.Dispose()
        $pen = New-Object System.Drawing.Pen $script:ui.SoftBorder, 1
        $g.DrawPath($pen, $path)
        $pen.Dispose()
        $path.Dispose()
    })
    $Box.Location = New-Object System.Drawing.Point(10, 5)
    $well.Controls.Add($Box)
    return $well
}
