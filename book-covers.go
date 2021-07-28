package main

import (
    "os"
    "io"
    "net/http"
    "errors"
    // "fmt"
    "log"
    "bufio"
    "image"
    "regexp"
    "image/color"

    _ "image/jpeg"
    _ "image/png"

    "github.com/disintegration/imaging"
)

func main() {
    README, _ := os.Open("README.md")
    scanner := bufio.NewScanner(README)

    re := regexp.MustCompile(`\[book\-(.*)\]: http(.*)`)

    for scanner.Scan() {
        if re.MatchString(scanner.Text()) {
            sub := re.FindStringSubmatch(scanner.Text())

            target := sub[1]
            source := sub[2]

            processImage(".../covers/" + target + ".png", "http" + source)
        }
    }
}

func processImage(target string, source string) {
    downloadFile(source, "temporary.png")

    img, err := os.Open("temporary.png")
    
    src, err := imaging.Open("temporary.png")
    if err != nil {
        log.Fatalf("failed to open image: %v", err)
    }

    imgData, _, err := image.DecodeConfig(img)

    src = imaging.CropAnchor(src, 300, 300, imaging.Center)

    src = imaging.Resize(src, 0, 200, imaging.Lanczos)
    prp := 20000 / imgData.Height

    dst := imaging.New(150, 200, color.NRGBA{0, 0, 0, 0})
    dst = imaging.Paste(dst, src, image.Pt(75 - (imgData.Width * prp / 100) / 2, 0))

    err = imaging.Save(dst, target)
    if err != nil {
        log.Fatalf("failed to save image: %v -- %s / %s", err, source, target)
    }
}

func downloadFile(URL, fileName string) error {
    response, err := http.Get(URL)
    if err != nil {
        return err
    }
    defer response.Body.Close()

    if response.StatusCode != 200 {
        return errors.New("Received non 200 response code")
    }
    file, err := os.Create(fileName)
    if err != nil {
        return err
    }
    defer file.Close()

    _, err = io.Copy(file, response.Body)
    if err != nil {
        return err
    }

    return nil
}