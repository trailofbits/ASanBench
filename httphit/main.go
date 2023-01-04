package main

import (
    "os"
    "strconv"
    "fmt"
    "context"
    "io"
    "net/http"
    "time"
)

type Response struct {
    Spawned time.Duration
    Latency time.Duration
}

func worker(url string, flag chan time.Duration, responses chan Response) {
    tr := &http.Transport {
        ForceAttemptHTTP2: true,
        MaxIdleConns: 0,
        MaxConnsPerHost: 0,
        DisableKeepAlives: false,
    }
    client := &http.Client{ Transport: tr }
    defer client.CloseIdleConnections();

    for {
        reqSpawn := <-flag
        if reqSpawn == time.Duration(0) {
            return
        }
        go func(spawned time.Duration) {
            start := time.Now()
            resp, err := client.Get(url)
            if err != nil {
                fmt.Fprintln(os.Stderr, reqSpawn, err)
                // Include dropped responses with a latency of 0 units.
                responses <- Response { spawned, time.Duration(0) }
                return
            }
            _, err = io.ReadAll(resp.Body)
            resp.Body.Close()
            elapsed := time.Since(start)
            responses <- Response { spawned, elapsed }
        }(reqSpawn)
    }
}

func stressServer(url string, numWorkers, reqsPerSec int, deadline time.Duration) {
    responses := make(chan Response)
    flag    := make(chan time.Duration)

    ctx, cancel := context.WithTimeout(context.Background(), deadline)
    defer cancel()

    for i := 0; i < numWorkers; i++ {
        go worker(url, flag, responses)
    }

    go func(){
        epoch := time.Now()
        for {
            select {
            case <-ctx.Done():
                for i := 0; i < numWorkers; i++ {
                    flag<-time.Duration(0)
                }
                responses <- Response{}
                return
            case <-time.After(time.Second / time.Duration(reqsPerSec)):
                flag<-time.Now().Sub(epoch)
            }
        }
    }()

    for {
        response := <-responses
        if response == (Response{}) {
            return
        }
        fmt.Println(response.Spawned.Milliseconds(), response.Latency.Microseconds())
    }
}

func main() {
    if len(os.Args[1:]) < 3 {
        fmt.Println(os.Args[0], "<reqs/s> <deadline> <url>")
        return
    }
    reqsPerSec, _ := strconv.Atoi(os.Args[1])
    seconds, _    := strconv.Atoi(os.Args[2])
    deadline      := time.Duration(seconds) * time.Second
    url           := os.Args[3]

    stressServer(url, 100, reqsPerSec, deadline)
}
